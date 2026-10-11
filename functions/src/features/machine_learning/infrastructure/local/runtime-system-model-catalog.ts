import {type SystemModel, type SystemModelSource} from "../../domain/repositories/system-model-source.js";

export type RuntimeSystemModel = SystemModel;

/** Der globale Katalog, wie ihn eine Runtime liest; die Dateien liegen im globalen Modellspeicher. */
export interface RuntimeSystemModelCatalog extends SystemModelSource {
  list(): Promise<readonly RuntimeSystemModel[]>;
}
