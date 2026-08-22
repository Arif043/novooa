import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";

export class ListAvailableModels {
  constructor(private readonly catalog: ModelCatalog) {}

  execute(teamId: string): Promise<readonly ModelCatalogEntry[]> {
    if (teamId.trim().length === 0) throw new Error("Die Team-ID fehlt.");
    return this.catalog.listAvailableFor(teamId);
  }
}
