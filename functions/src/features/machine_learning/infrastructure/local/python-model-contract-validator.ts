import {type ModelContract} from "../../domain/entities/model-contract.js";
import {type MlServiceJsonClient} from "../ml-service-http.js";

export interface ModelContractValidator {
  validate(contract: ModelContract): Promise<void>;
}

/**
 * Lässt den ML-Dienst prüfen, ob jede Pipeline des Vertrags zusammenpasst: bekannte
 * Transformationen und passende Wertarten (z. B. kein Audio-Schritt an einem Bildeingang).
 * Der ML-Dienst bleibt damit die verbindliche Quelle der unterstützten Transformationen.
 */
export class PythonModelContractValidator implements ModelContractValidator {
  constructor(private readonly client: MlServiceJsonClient) {}

  async validate(contract: ModelContract): Promise<void> {
    await this.client.post("/v1/contract-validations", JSON.stringify({contract}));
  }
}

export class UnavailablePythonModelContractValidator implements ModelContractValidator {
  async validate(): Promise<void> {
    throw new Error("Die lokale Python-Inferenz ist nicht verfügbar.");
  }
}
