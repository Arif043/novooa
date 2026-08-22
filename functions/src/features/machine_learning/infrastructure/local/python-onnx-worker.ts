import {type ModelTensor} from "../../domain/entities/model-tensor.js";

export type PythonOnnxWorkerRequest = {
  artifact: Uint8Array;
  inputs: readonly ModelTensor[];
  outputNames: readonly string[];
};

export interface PythonOnnxWorker {
  execute(request: PythonOnnxWorkerRequest): Promise<readonly ModelTensor[]>;
}
