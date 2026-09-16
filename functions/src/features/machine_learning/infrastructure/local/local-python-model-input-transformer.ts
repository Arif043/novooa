import {validateModelInputSource} from "../../domain/entities/model-input-source.js";
import {type ModelTensor} from "../../domain/entities/model-tensor.js";
import {
  type ModelInputTransformer,
  type ModelInputTransformationRequest,
} from "../../domain/repositories/model-input-transformer.js";
import {type PythonJsonProcess} from "./local-python-process.js";
import {
  pythonImageTransformationInputJson,
  transformedImageTensorFromJson,
} from "./python-image-input-transformer-codec.js";

export class LocalPythonModelInputTransformer implements ModelInputTransformer {
  constructor(private readonly process: PythonJsonProcess) {}

  async transform(request: ModelInputTransformationRequest): Promise<ModelTensor> {
    validateModelInputSource(request.source, request.input);
    if (request.source.type === "tensor") return tensorFrom(request);
    if (request.source.type === "image") return this.transformImage(request);
    throw new Error(`Der lokale Transformer unterstützt ${request.source.type}-Quellen noch nicht.`);
  }

  private async transformImage(
    request: ModelInputTransformationRequest,
  ): Promise<ModelTensor> {
    const payload = pythonImageTransformationInputJson(request);
    return transformedImageTensorFromJson(await this.process.execute(payload));
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
