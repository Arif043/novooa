import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";

export interface ModelCatalog {
  save(entry: ModelCatalogEntry): Promise<void>;
  listAvailableFor(teamId: string): Promise<readonly ModelCatalogEntry[]>;
  findAvailableFor(
    teamId: string,
    modelId: string,
  ): Promise<ModelCatalogEntry | null>;
}
