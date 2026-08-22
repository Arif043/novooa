import {
  type ModelCatalogEntry,
  validateModelCatalogEntry,
} from "../entities/model-catalog-entry.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";

export class RegisterModelCatalogEntry {
  constructor(private readonly catalog: ModelCatalog) {}

  async execute(entry: ModelCatalogEntry): Promise<void> {
    validateModelCatalogEntry(entry);
    await this.catalog.save(entry);
  }
}
