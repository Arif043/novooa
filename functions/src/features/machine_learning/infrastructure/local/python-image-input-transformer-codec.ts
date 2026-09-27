import {type ModelInputTransformationRequest} from "../../domain/repositories/model-input-transformer.js";
import {type ModelTensor} from "../../domain/entities/model-tensor.js";
import {modelTensorFromJson} from "./model-tensor-json-codec.js";

export function pythonModelInputTransformationJson(
  request: ModelInputTransformationRequest,
): string {
  return JSON.stringify({
    input: request.input,
    source: sourceFor(request),
    ...(request.modelKey === undefined ? {} : {modelKey: request.modelKey}),
  });
}

export function transformedModelTensorFromJson(value: string): ModelTensor {
  const data = objectFrom(JSON.parse(value));
  return modelTensorFromJson(data.tensor);
}

function sourceFor(request: ModelInputTransformationRequest): object {
  const source = request.source;
  if (source.type === "image" || source.type === "audio" || source.type === "file") {
    return {type: source.type, contentType: source.contentType, dataBase64: Buffer.from(source.bytes).toString("base64")};
  }
  if (source.type === "text" || source.type === "datetime") return {type: source.type, value: source.value};
  if (source.type === "number" || source.type === "boolean" || source.type === "json") return {type: source.type, value: source.value};
  throw new Error("Die Tensorquelle benötigt keine Python-Transformation.");
}

function objectFrom(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Die Antwort des lokalen Bildtransformators ist ungültig.");
  }
  return value as Record<string, unknown>;
}
