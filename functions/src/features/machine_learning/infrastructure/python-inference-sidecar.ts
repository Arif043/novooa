import {type ModelArtifactReference} from "../domain/entities/model-artifact-reference.js";
import {
  type ModelRuntimeResource,
  validateModelRuntimeResources,
} from "../domain/entities/model-runtime-resource.js";
import {type ModelOutput} from "../domain/entities/model-contract.js";
import {type ModelTensor} from "../domain/entities/model-tensor.js";
import {
  type ModelInferenceRuntime,
  type ModelInputPreparationRuntime,
  type ModelRuntimeOutput,
  type ModelRuntimeRequest,
} from "../domain/repositories/model-inference-runtime.js";
import {modelTensorFromJson, modelTensorToJson} from "./local/model-tensor-json-codec.js";
import {type ModelOutputValue} from "../domain/entities/model-output-value.js";

export interface PythonInferenceSidecar {
  load(request: SidecarModelLoadRequest): Promise<void>;
  infer(request: SidecarInferenceRequest): Promise<readonly ModelRuntimeOutput[]>;
}

export type SidecarModelLoadRequest = {
  readonly reference: ModelArtifactReference;
  readonly artifact: Uint8Array;
  readonly resources: readonly ModelRuntimeResource[];
};

export type SidecarInferenceRequest = {
  readonly modelKey: string;
  readonly inputs: readonly ModelTensor[];
  readonly outputs: readonly ModelOutput[];
};

export class SidecarOnnxInferenceRuntime implements ModelInferenceRuntime, ModelInputPreparationRuntime {
  private readonly loadedModels = new Map<string, Promise<void>>();

  constructor(private readonly sidecar: PythonInferenceSidecar) {}

  async execute(request: ModelRuntimeRequest): Promise<readonly ModelRuntimeOutput[]> {
    const reference = request.model.artifactReference;
    const resources = request.resources ?? [];
    validateModelRuntimeResources(resources);
    await this.load(reference, request.artifact, resources);
    return this.inferWithReload(reference, resources, request);
  }

  async prepareInputs(request: ModelRuntimeRequest): Promise<string> {
    const resources = request.resources ?? [];
    validateModelRuntimeResources(resources);
    await this.load(request.model.artifactReference, request.artifact, resources);
    return modelKey(request.model.artifactReference, resources);
  }

  private async load(
    reference: ModelArtifactReference,
    artifact: Uint8Array,
    resources: readonly ModelRuntimeResource[],
  ): Promise<void> {
    const key = modelKey(reference, resources);
    const loading = this.loadedModels.get(key) ?? this.startLoading(key, reference, artifact, resources);
    return loading;
  }

  private startLoading(
    key: string,
    reference: ModelArtifactReference,
    artifact: Uint8Array,
    resources: readonly ModelRuntimeResource[],
  ) {
    const loading = this.sidecar.load({reference, artifact, resources}).catch((error: unknown) => {
      this.loadedModels.delete(key);
      throw error;
    });
    this.loadedModels.set(key, loading);
    return loading;
  }

  private async inferWithReload(
    reference: ModelArtifactReference,
    resources: readonly ModelRuntimeResource[],
    request: ModelRuntimeRequest,
  ) {
    try {
      return await this.infer(reference, resources, request);
    } catch (error) {
      if (!(error instanceof ModelNotLoadedError)) throw error;
      this.loadedModels.delete(modelKey(reference, resources));
      await this.load(reference, request.artifact, resources);
      return this.infer(reference, resources, request);
    }
  }

  private infer(
    reference: ModelArtifactReference,
    resources: readonly ModelRuntimeResource[],
    request: ModelRuntimeRequest,
  ) {
    return this.sidecar.infer({
      modelKey: modelKey(reference, resources),
      inputs: request.inputs,
      outputs: request.model.contract.outputs,
    });
  }
}

export class HttpPythonInferenceSidecar implements PythonInferenceSidecar {
  constructor(private readonly baseUrl: string) {}

  async load(request: SidecarModelLoadRequest): Promise<void> {
    await this.post("/v1/models", {
      modelKey: modelKey(request.reference, request.resources),
      modelBase64: Buffer.from(request.artifact).toString("base64"),
      resources: request.resources.map(resourceForJson),
    });
  }

  async infer(request: SidecarInferenceRequest): Promise<readonly ModelRuntimeOutput[]> {
    const body = await this.post("/v1/inferences", {
      modelKey: request.modelKey,
      inputs: request.inputs.map(modelTensorToJson),
      outputs: request.outputs,
    });
    return runtimeOutputs(body);
  }

  private async post(path: string, body: object): Promise<unknown> {
    const response = await fetch(new URL(path, this.baseUrl), {
      method: "POST", headers: {"content-type": "application/json"}, body: JSON.stringify(body),
    });
    const payload = await response.json() as unknown;
    if (response.status === 404 && isMissingModel(payload)) throw new ModelNotLoadedError();
    if (!response.ok) throw new Error(errorMessage(payload));
    return payload;
  }
}

export class ModelNotLoadedError extends Error {}

function runtimeOutputs(value: unknown): readonly ModelRuntimeOutput[] {
  if (!isRecord(value) || !Array.isArray(value.outputs)) throw new Error("Der Python-Sidecar lieferte keine Ausgaben.");
  return value.outputs.map((output) => {
    const data = recordFrom(output);
    const tensor = modelTensorFromJson(data);
    return {
      ...tensor,
      tensor,
      transformationValues: transformationValuesFrom(data.transformationValues),
    };
  });
}

function transformationValuesFrom(value: unknown): Readonly<Record<string, ModelOutputValue>> {
  const data = recordFrom(value);
  return Object.fromEntries(Object.entries(data).map(([name, item]) => [name, outputValueFrom(item)]));
}

function outputValueFrom(value: unknown): ModelOutputValue {
  if (typeof value === "string" || typeof value === "boolean") return value;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (Array.isArray(value)) return value.map(outputValueFrom);
  const data = recordFrom(value);
  return Object.fromEntries(Object.entries(data).map(([name, item]) => [name, outputValueFrom(item)]));
}

export function modelKey(
  reference: ModelArtifactReference,
  resources: readonly ModelRuntimeResource[] = [],
): string {
  const resourceFingerprint = resources
    .map((resource) => `${resource.name}:${resource.sha256}`)
    .sort()
    .join(",");
  return `${reference.artifactId}:${reference.versionId}:${reference.sha256}:${resourceFingerprint}`;
}

function resourceForJson(resource: ModelRuntimeResource): object {
  return {
    name: resource.name,
    contentType: resource.contentType,
    sha256: resource.sha256,
    dataBase64: Buffer.from(resource.bytes).toString("base64"),
  };
}

function isMissingModel(value: unknown): boolean {
  return isRecord(value) && value.code === "model_not_loaded";
}

function errorMessage(value: unknown): string {
  return isRecord(value) && typeof value.error === "string" ? value.error : "Der Python-Sidecar ist fehlgeschlagen.";
}

function recordFrom(value: unknown): Record<string, unknown> {
  if (!isRecord(value)) throw new Error("Die Antwort des Python-Sidecars ist ungültig.");
  return value;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
