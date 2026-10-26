import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";

/** Der globale Katalog aus Sicht des Betreibers, der Systemmodelle veröffentlicht. */
export interface SystemModelRegistry {
  /** Der veröffentlichte Systemeintrag mit dieser Modell-ID; `null`, wenn es keinen gibt. */
  findSystemEntry(modelId: string): Promise<ModelCatalogEntry | null>;
  save(entry: ModelCatalogEntry): Promise<void>;
}
