import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelContract} from "../entities/model-contract.js";
import {type ModelArtifactPublication} from "./model-artifact-publisher.js";

/** Ein Modell des globalen Katalogs, dessen Artefakt sich bei Bedarf laden lässt. */
export type SystemModel = {
  entry: ModelCatalogEntry;
  fetchArtifact(): Promise<ModelArtifactPublication>;
};

/** Der globale Modellkatalog als Quelle für den lokalen Modell-Cache. */
export interface SystemModelSource {
  find(modelId: string): Promise<SystemModel | null>;
}

/** Prüft, ob die Runtime alle Transformationen eines Modellvertrags kennt. */
export interface ModelContractCheck {
  validate(contract: ModelContract): Promise<void>;
}
