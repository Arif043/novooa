import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelSearchCriteria} from "../entities/model-search-criteria.js";
import {type ModelTagVocabulary} from "../entities/model-tag-vocabulary.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {type ModelTagVocabularySource} from "../repositories/model-tag-vocabulary-source.js";
import {type SystemModelCatalog} from "../repositories/system-model-catalog.js";

/** Treffer samt Vokabular, damit Aufrufer die Tags in ihrer Sprache benennen können. */
export type ModelSearchOutcome = {
  entries: readonly ModelCatalogEntry[];
  vocabulary: ModelTagVocabulary;
};

/** Findet passende Modelle: ohne Team nur im globalen Katalog, sonst inklusive Team-Modellen. */
export class SearchModelCatalog {
  constructor(
    private readonly catalog: ModelCatalog,
    private readonly systemCatalog: SystemModelCatalog,
    private readonly tagVocabulary: ModelTagVocabularySource,
  ) {}

  async execute(criteria: ModelSearchCriteria, teamId: string | null): Promise<ModelSearchOutcome> {
    const [entries, vocabulary] = await Promise.all([this.entriesFor(teamId), this.tagVocabulary.load()]);
    const found = entries
      .filter((entry) => matchesTask(entry, criteria) && matchesLanguages(entry, criteria))
      .map((entry) => ({entry, score: relevance(entry, criteria, vocabulary)}))
      .filter(({score}) => criteria.terms.length === 0 || score > 0)
      .sort((left, right) => right.score - left.score)
      .slice(0, criteria.limit)
      .map(({entry}) => entry);
    return {entries: found, vocabulary};
  }

  private entriesFor(teamId: string | null): Promise<readonly ModelCatalogEntry[]> {
    if (teamId === null || teamId.trim().length === 0) return this.systemCatalog.listSystemEntries();
    return this.catalog.listAvailableFor(teamId);
  }
}

function matchesTask(entry: ModelCatalogEntry, criteria: ModelSearchCriteria): boolean {
  return criteria.task === null || entry.task === criteria.task;
}

/** Sprachunabhängige Modelle (ohne Sprachen) passen immer; `de` passt auch zu `de-AT`. */
function matchesLanguages(entry: ModelCatalogEntry, criteria: ModelSearchCriteria): boolean {
  if (criteria.languages.length === 0 || entry.languages.length === 0) return true;
  return entry.languages.some((language) => criteria.languages.some(
    (wanted) => baseLanguage(language) === baseLanguage(wanted),
  ));
}

function baseLanguage(language: string): string {
  return language.toLowerCase().split("-")[0] ?? "";
}

function relevance(entry: ModelCatalogEntry, criteria: ModelSearchCriteria, vocabulary: ModelTagVocabulary): number {
  const searchableText = searchableTextOf(entry);
  const topics = vocabulary.withAncestors(entry.tags);
  return criteria.terms.filter((term) => searchableText.includes(term) || matchesTopic(topics, term, vocabulary)).length;
}

/** Ein Begriff trifft ein Thema über dessen Bezeichnung oder Synonym; Obertags zählen mit. */
function matchesTopic(topics: readonly string[], term: string, vocabulary: ModelTagVocabulary): boolean {
  const matching = vocabulary.keysMatching(term);
  return topics.some((topic) => matching.has(topic));
}

function searchableTextOf(entry: ModelCatalogEntry): string {
  const translations = Object.values(entry.translations ?? {})
    .flatMap((translation) => [translation.title, translation.description]);
  return [entry.id, entry.title, entry.description, entry.task, ...entry.tags, ...translations]
    .join("\n")
    .toLowerCase();
}
