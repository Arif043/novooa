import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelSearchCriteria} from "../entities/model-search-criteria.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {type SystemModelCatalog} from "../repositories/system-model-catalog.js";

/** Findet passende Modelle: ohne Team nur im globalen Katalog, sonst inklusive Team-Modellen. */
export class SearchModelCatalog {
  constructor(
    private readonly catalog: ModelCatalog,
    private readonly systemCatalog: SystemModelCatalog,
  ) {}

  async execute(
    criteria: ModelSearchCriteria,
    teamId: string | null,
  ): Promise<readonly ModelCatalogEntry[]> {
    const entries = await this.entriesFor(teamId);
    return entries
      .filter((entry) => matchesTask(entry, criteria) && matchesLanguages(entry, criteria))
      .map((entry) => ({entry, score: relevance(entry, criteria)}))
      .filter(({score}) => criteria.terms.length === 0 || score > 0)
      .sort((left, right) => right.score - left.score)
      .slice(0, criteria.limit)
      .map(({entry}) => entry);
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

function relevance(entry: ModelCatalogEntry, criteria: ModelSearchCriteria): number {
  const searchableText = searchableTextOf(entry);
  return criteria.terms.filter((term) => searchableText.includes(term)).length;
}

function searchableTextOf(entry: ModelCatalogEntry): string {
  const translations = Object.values(entry.translations ?? {})
    .flatMap((translation) => [translation.title, translation.description, ...(translation.tags ?? [])]);
  return [entry.id, entry.title, entry.description, entry.task, ...entry.tags, ...translations]
    .join("\n")
    .toLowerCase();
}
