import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";

/**
 * Liest nur die Einträge des globalen Katalogs. Für Aufrufer ohne Team-Bezug,
 * etwa den KI-Agenten hinter dem Relay einer lokalen Runtime.
 */
export interface SystemModelCatalog {
  listSystemEntries(): Promise<readonly ModelCatalogEntry[]>;
}
