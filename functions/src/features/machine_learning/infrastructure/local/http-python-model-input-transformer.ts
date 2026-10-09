import {validateModelInputSource} from "../../domain/entities/model-input-source.js";
import {type ModelTensor} from "../../domain/entities/model-tensor.js";
import {
  type ModelInputTransformationRequest,
  type ModelInputTransformer,
} from "../../domain/repositories/model-input-transformer.js";
import {
  pythonModelInputTransformationJson,
  transformedModelTensorFromJson,
} from "./python-image-input-transformer-codec.js";

export interface PythonTransformHttpClient {
  post(url: string, body: string): Promise<unknown>;
}

export class HttpPythonModelInputTransformer implements ModelInputTransformer {
  constructor(
    private readonly sidecarUrl: string,
    private readonly httpClient: PythonTransformHttpClient = new FetchPythonTransformHttpClient(),
  ) {}

  async transform(request: ModelInputTransformationRequest): Promise<ModelTensor> {
    validateModelInputSource(request.source, request.input);
    if (request.source.type === "tensor") return tensorFrom(request);
    // Welche Quellen unterstützt werden, entscheidet der Python-Sidecar (und schon beim Import
    // die Vertragsprüfung); eine zweite Liste hier würde nur auseinanderlaufen.
    const payload = await this.httpClient.post(
      new URL("/v1/input-transforms", this.sidecarUrl).toString(),
      pythonModelInputTransformationJson(request),
    );
    return transformedModelTensorFromJson(JSON.stringify(payload));
  }
}

export class FetchPythonTransformHttpClient implements PythonTransformHttpClient {
  async post(url: string, body: string): Promise<unknown> {
    const response = await fetch(url, {
      method: "POST", headers: {"content-type": "application/json"}, body,
    });
    const payload = await response.json() as unknown;
    if (!response.ok) throw new Error(errorMessage(payload));
    return payload;
  }
}

function tensorFrom(request: ModelInputTransformationRequest): ModelTensor {
  if (request.input.transformations.length > 0) {
    throw new Error("Tensorquellen mit Vorverarbeitung werden noch nicht unterstützt.");
  }
  if (request.source.type !== "tensor") throw new Error("Die Tensorquelle fehlt.");
  if (request.source.tensor.name !== request.input.name) {
    throw new Error("Der Name der Tensorquelle stimmt nicht mit dem Modellvertrag überein.");
  }
  return request.source.tensor;
}

function errorMessage(value: unknown): string {
  if (isRecord(value) && typeof value.error === "string") return value.error;
  return "Der Python-Sidecar konnte die Modelleingabe nicht transformieren.";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
