import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelCatalog} from "../../domain/repositories/model-catalog.js";
import {SystemModelNotFoundError, type CacheSystemModel} from "../../domain/usecases/cache-system-model.js";

/**
 * Katalog für den Inferenzpfad: Fehlt ein Modell lokal — etwa nach dem Import einer Aufgabe auf eine
 * andere Runtime oder nachdem es aus dem Cache entfernt wurde —, lädt der Lauf es aus dem globalen
 * Katalog nach, bevor er es ausführt.
 */
export class SelfCachingModelCatalog implements ModelCatalog {
  constructor(
    private readonly local: ModelCatalog,
    private readonly cache: CacheSystemModel,
  ) {}

  save(entry: ModelCatalogEntry): Promise<void> {
    return this.local.save(entry);
  }

  listAvailableFor(teamId: string): Promise<readonly ModelCatalogEntry[]> {
    return this.local.listAvailableFor(teamId);
  }

  async findAvailableFor(teamId: string, modelId: string): Promise<ModelCatalogEntry | null> {
    const local = await this.local.findAvailableFor(teamId, modelId);
    if (local !== null) return local;
    try {
      return await this.cache.execute(teamId, modelId);
    } catch (error) {
      // Weder lokal noch im Katalog: wie bisher „nicht verfügbar“.
      if (error instanceof SystemModelNotFoundError) return null;
      throw error;
    }
  }
}
