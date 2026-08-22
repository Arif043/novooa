import {type ModelTensor} from "../../domain/entities/model-tensor.js";
import {
  type ModelInferenceRuntime,
  type ModelRuntimeRequest,
} from "../../domain/repositories/model-inference-runtime.js";
import {type PythonOnnxWorker} from "./python-onnx-worker.js";

export class LocalOnnxInferenceRuntime implements ModelInferenceRuntime {
  constructor(private readonly worker: PythonOnnxWorker) {}

  async execute(request: ModelRuntimeRequest): Promise<readonly ModelTensor[]> {
    return this.worker.execute({
      artifact: request.artifact,
      inputs: request.inputs,
      outputNames: request.model.contract.outputs.map((output) => output.name),
    });
  }
}
