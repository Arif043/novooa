import {
  type ModelInference,
  type ModelInferenceRequest,
  type ModelInferenceResult,
} from "../../domain/repositories/model-inference.js";

export class UnavailableLocalModelInference implements ModelInference {
  async execute(_request: ModelInferenceRequest): Promise<ModelInferenceResult> {
    throw new Error("Die lokale ONNX-Inferenz ist noch nicht gestartet.");
  }
}
