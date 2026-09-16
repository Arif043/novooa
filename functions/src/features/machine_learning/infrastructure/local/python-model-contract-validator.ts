import {type ModelContract, type TransformationPipeline} from "../../domain/entities/model-contract.js";

export interface ModelContractValidator {
  validate(contract: ModelContract): Promise<void>;
}

export interface PythonTransformationCapabilityClient {
  get(url: string): Promise<unknown>;
}

export class PythonModelContractValidator implements ModelContractValidator {
  constructor(
    private readonly sidecarUrl: string,
    private readonly client: PythonTransformationCapabilityClient = new FetchPythonTransformationCapabilityClient(),
  ) {}

  async validate(contract: ModelContract): Promise<void> {
    const capabilities = await this.capabilities();
    validateTransformations(contract.inputs.map((input) => input.transformations), capabilities.inputs, "Eingabe");
    validateTransformations(contract.outputs.map((output) => output.transformations), capabilities.outputs, "Ausgabe");
  }

  private async capabilities(): Promise<TransformationCapabilities> {
    const payload = await this.client.get(new URL("/v1/transformation-capabilities", this.sidecarUrl).toString());
    return transformationCapabilitiesFrom(payload);
  }
}

export class FetchPythonTransformationCapabilityClient implements PythonTransformationCapabilityClient {
  async get(url: string): Promise<unknown> {
    const response = await fetch(url);
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

type TransformationCapabilities = {
  inputs: ReadonlySet<string>;
  outputs: ReadonlySet<string>;
};

function validateTransformations(
  pipelines: readonly TransformationPipeline[],
  supported: ReadonlySet<string>,
  kind: string,
): void {
  for (const transformation of pipelines.flat()) {
    if (!supported.has(transformation.type)) {
      throw new Error(`Die ${kind}-Transformation ${transformation.type} wird von der lokalen Runtime nicht unterstützt.`);
    }
  }
}

function transformationCapabilitiesFrom(value: unknown): TransformationCapabilities {
  const data = record(value);
  return {
    inputs: typesFrom(data.inputTransformationTypes),
    outputs: typesFrom(data.outputTransformationTypes),
  };
}

function typesFrom(value: unknown): ReadonlySet<string> {
  if (!Array.isArray(value) || value.some((item) => typeof item !== "string" || item.length === 0)) {
    throw new Error("Der Python-Sidecar lieferte ungültige Transformationsfähigkeiten.");
  }
  return new Set(value);
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new Error("Der Python-Sidecar lieferte ungültige Transformationsfähigkeiten.");
}

function errorMessage(value: unknown): string {
  if (value !== null && typeof value === "object" && "error" in value && typeof value.error === "string") return value.error;
  return "Die Transformationsfähigkeiten konnten nicht geladen werden.";
}
