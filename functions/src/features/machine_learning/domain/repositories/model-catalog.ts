import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";

export interface ModelCatalog {
  save(entry: ModelCatalogEntry): Promise<void>;
  listAvailableFor(teamId: string): Promise<readonly ModelCatalogEntry[]>;
  findAvailableFor(
    teamId: string,
    modelId: string,
  ): Promise<ModelCatalogEntry | null>;
}

/** Administrative operations that are only available for locally owned models. */
export interface TeamModelCatalog extends ModelCatalog {
  removeTeamEntry(teamId: string, modelId: string): Promise<boolean>;
}
