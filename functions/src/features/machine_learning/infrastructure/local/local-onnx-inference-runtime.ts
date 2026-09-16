import {
  type ModelInferenceRuntime,
  type ModelRuntimeRequest,
} from "../../domain/repositories/model-inference-runtime.js";
import {type PythonOnnxWorker} from "./python-onnx-worker.js";

export class LocalOnnxInferenceRuntime implements ModelInferenceRuntime {
  constructor(private readonly worker: PythonOnnxWorker) {}

  async execute(request: ModelRuntimeRequest) {
    return this.worker.execute({
      artifact: request.artifact,
      inputs: request.inputs,
      outputs: request.model.contract.outputs,
      outputParameters: request.outputParameters,
    });
  }
}
