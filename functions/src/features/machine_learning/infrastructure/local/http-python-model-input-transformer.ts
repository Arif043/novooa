import {type MlServiceJsonClient} from "../ml-service-http.js";
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

export class HttpPythonModelInputTransformer implements ModelInputTransformer {
  constructor(private readonly client: MlServiceJsonClient) {}

  async transform(request: ModelInputTransformationRequest): Promise<ModelTensor> {
    validateModelInputSource(request.source, request.input);
    if (request.source.type === "tensor") return tensorFrom(request);
    // Welche Quellen unterstützt werden, entscheidet der Python-Sidecar (und schon beim Import
    // die Vertragsprüfung); eine zweite Liste hier würde nur auseinanderlaufen.
    const payload = await this.client.post("/v1/input-transforms", pythonModelInputTransformationJson(request));
    return transformedModelTensorFromJson(JSON.stringify(payload));
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
