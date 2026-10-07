import {isModelTask, type ModelTask} from "./model-task.js";

export const maxModelSearchResults = 20;

/** Wonach im Modellkatalog gesucht wird; leere Felder schränken nicht ein. */
export class ModelSearchCriteria {
  readonly languages: readonly string[];
  readonly terms: readonly string[];

  constructor(
    readonly task: ModelTask | null,
    languages: readonly string[],
    query: string,
    readonly limit: number,
  ) {
    if (task !== null && !isModelTask(task)) throw new Error(`Die Modellaufgabe „${String(task)}“ ist unbekannt.`);
    if (!Number.isInteger(limit) || limit < 1 || limit > maxModelSearchResults) {
      throw new Error(`Die Trefferzahl muss zwischen 1 und ${maxModelSearchResults} liegen.`);
    }
    this.languages = languages.map((language) => language.trim().toLowerCase()).filter(Boolean);
    this.terms = searchTermsFrom(query);
  }
}

function searchTermsFrom(query: string): string[] {
  return query.toLowerCase().split(/[^\p{L}\p{N}]+/u).filter((term) => term.length > 1);
}
