import {
  type ModelInference,
  type ModelInferenceRequest,
  type ModelInferenceResult,
} from "../domain/repositories/model-inference.js";

export class UnavailableModelInference implements ModelInference {
  async execute(_request: ModelInferenceRequest): Promise<ModelInferenceResult> {
    throw new Error("Die ONNX-Inferenz ist in der Cloud noch nicht eingerichtet.");
  }
}
