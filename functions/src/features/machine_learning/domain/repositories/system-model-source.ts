import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelContract} from "../entities/model-contract.js";

/** Ein Modell des globalen Katalogs; seine Dateien liegen im globalen Modellspeicher. */
export type SystemModel = {
  entry: ModelCatalogEntry;
};

/** Der globale Modellkatalog als Quelle für den Katalog eines Arbeitsbereichs. */
export interface SystemModelSource {
  find(modelId: string): Promise<SystemModel | null>;
}

/** Prüft, ob die Runtime alle Transformationen eines Modellvertrags kennt. */
export interface ModelContractCheck {
  validate(contract: ModelContract): Promise<void>;
}
