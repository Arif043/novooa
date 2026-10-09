import {type ModelOutput} from "../../domain/entities/model-contract.js";
import {
  type ModelRuntimeOutput,
} from "../../domain/repositories/model-inference-runtime.js";
import {type ModelTensor} from "../../domain/entities/model-tensor.js";

export type PythonOnnxWorkerRequest = {
  readonly artifact: Uint8Array;
  readonly inputs: readonly ModelTensor[];
  readonly outputs: readonly ModelOutput[];
};

export interface PythonOnnxWorker {
  execute(request: PythonOnnxWorkerRequest): Promise<readonly ModelRuntimeOutput[]>;
}
