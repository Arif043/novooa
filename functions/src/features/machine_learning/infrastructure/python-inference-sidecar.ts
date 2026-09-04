import {type ModelArtifactReference} from "../domain/entities/model-artifact-reference.js";
import {type ModelTensor} from "../domain/entities/model-tensor.js";
import {type ModelInferenceRuntime, type ModelRuntimeRequest} from "../domain/repositories/model-inference-runtime.js";
import {modelTensorFromJson, modelTensorToJson} from "./local/model-tensor-json-codec.js";

export interface PythonInferenceSidecar {
  load(reference: ModelArtifactReference, artifact: Uint8Array): Promise<void>;
  infer(request: SidecarInferenceRequest): Promise<readonly ModelTensor[]>;
}

export type SidecarInferenceRequest = {
  reference: ModelArtifactReference;
  inputs: readonly ModelTensor[];
  outputNames: readonly string[];
};

export class SidecarOnnxInferenceRuntime implements ModelInferenceRuntime {
  private readonly loadedModels = new Map<string, Promise<void>>();

  constructor(private readonly sidecar: PythonInferenceSidecar) {}

  async execute(request: ModelRuntimeRequest): Promise<readonly ModelTensor[]> {
    const reference = request.model.artifactReference;
    await this.load(reference, request.artifact);
    return this.inferWithReload(reference, request);
  }

  private async load(reference: ModelArtifactReference, artifact: Uint8Array): Promise<void> {
    const key = modelKey(reference);
    const loading = this.loadedModels.get(key) ?? this.startLoading(key, reference, artifact);
    return loading;
  }

  private startLoading(key: string, reference: ModelArtifactReference, artifact: Uint8Array) {
    const loading = this.sidecar.load(reference, artifact).catch((error: unknown) => {
      this.loadedModels.delete(key);
      throw error;
    });
    this.loadedModels.set(key, loading);
    return loading;
  }

  private async inferWithReload(reference: ModelArtifactReference, request: ModelRuntimeRequest) {
    try {
      return await this.infer(reference, request);
    } catch (error) {
      if (!(error instanceof ModelNotLoadedError)) throw error;
      this.loadedModels.delete(modelKey(reference));
      await this.load(reference, request.artifact);
      return this.infer(reference, request);
    }
  }

  private infer(reference: ModelArtifactReference, request: ModelRuntimeRequest) {
    return this.sidecar.infer({
      reference,
      inputs: request.inputs,
      outputNames: request.model.contract.outputs.map((output) => output.name),
    });
  }
}

export class HttpPythonInferenceSidecar implements PythonInferenceSidecar {
  constructor(private readonly baseUrl: string) {}

  async load(reference: ModelArtifactReference, artifact: Uint8Array): Promise<void> {
    await this.post("/v1/models", {
      modelKey: modelKey(reference),
      modelBase64: Buffer.from(artifact).toString("base64"),
    });
  }

  async infer(request: SidecarInferenceRequest): Promise<readonly ModelTensor[]> {
    const body = await this.post("/v1/inferences", {
      modelKey: modelKey(request.reference),
      inputs: request.inputs.map(modelTensorToJson),
      outputNames: request.outputNames,
    });
    return outputTensors(body);
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

function outputTensors(value: unknown): readonly ModelTensor[] {
  if (!isRecord(value) || !Array.isArray(value.outputs)) throw new Error("Der Python-Sidecar lieferte keine Tensoren.");
  return value.outputs.map(modelTensorFromJson);
}

function modelKey(reference: ModelArtifactReference): string {
  return `${reference.artifactId}:${reference.versionId}:${reference.sha256}`;
}

function isMissingModel(value: unknown): boolean {
  return isRecord(value) && value.code === "model_not_loaded";
}

function errorMessage(value: unknown): string {
  return isRecord(value) && typeof value.error === "string" ? value.error : "Der Python-Sidecar ist fehlgeschlagen.";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
