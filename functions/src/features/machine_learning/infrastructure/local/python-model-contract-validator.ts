import {type ModelContract} from "../../domain/entities/model-contract.js";

export interface ModelContractValidator {
  validate(contract: ModelContract): Promise<void>;
}

export interface PythonContractValidationClient {
  post(url: string, body: unknown): Promise<unknown>;
}

/**
 * Lässt den Python-Sidecar prüfen, ob jede Pipeline des Vertrags zusammenpasst: bekannte
 * Transformationen und passende Wertarten (z. B. kein Audio-Schritt an einem Bildeingang).
 * Der Sidecar bleibt damit die verbindliche Quelle der unterstützten Transformationen.
 */
export class PythonModelContractValidator implements ModelContractValidator {
  constructor(
    private readonly sidecarUrl: string,
    private readonly client: PythonContractValidationClient = new FetchPythonContractValidationClient(),
  ) {}

  async validate(contract: ModelContract): Promise<void> {
    await this.client.post(new URL("/v1/contract-validations", this.sidecarUrl).toString(), {contract});
  }
}

export class FetchPythonContractValidationClient implements PythonContractValidationClient {
  async post(url: string, body: unknown): Promise<unknown> {
    const response = await fetch(url, {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify(body),
    });
    const payload = await response.json() as unknown;
    if (!response.ok) throw new Error(errorMessage(payload));
    return payload;
  }
}

export class UnavailablePythonModelContractValidator implements ModelContractValidator {
  async validate(): Promise<void> {
    throw new Error("Die lokale Python-Inferenz ist nicht verfügbar.");
  }
}

function errorMessage(value: unknown): string {
  if (value !== null && typeof value === "object" && "error" in value && typeof value.error === "string") return value.error;
  return "Der Modellvertrag konnte nicht geprüft werden.";
}
