import {type ModelInputTransformationRequest} from "../../domain/repositories/model-input-transformer.js";
import {type ModelTensor} from "../../domain/entities/model-tensor.js";
import {modelTensorFromJson} from "./model-tensor-json-codec.js";

export function pythonImageTransformationInputJson(
  request: ModelInputTransformationRequest,
): string {
  if (request.source.type !== "image") {
    throw new Error("Der lokale Bildtransformer benötigt eine Bildquelle.");
  }
  return JSON.stringify({
    input: request.input,
    source: {
      contentType: request.source.contentType,
      dataBase64: Buffer.from(request.source.bytes).toString("base64"),
    },
  });
}

export function transformedImageTensorFromJson(value: string): ModelTensor {
  const data = objectFrom(JSON.parse(value));
  return modelTensorFromJson(data.tensor);
}

function objectFrom(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Die Antwort des lokalen Bildtransformators ist ungültig.");
  }
  return value as Record<string, unknown>;
}
