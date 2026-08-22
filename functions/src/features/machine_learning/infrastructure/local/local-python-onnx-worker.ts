import {type PythonOnnxWorker, type PythonOnnxWorkerRequest} from "./python-onnx-worker.js";
import {type PythonJsonProcess} from "./local-python-process.js";
import {
  pythonOnnxWorkerInputJson,
  pythonOnnxWorkerOutputFromJson,
} from "./python-onnx-worker-codec.js";

export class LocalPythonOnnxWorker implements PythonOnnxWorker {
  constructor(private readonly process: PythonJsonProcess) {}

  async execute(request: PythonOnnxWorkerRequest) {
    const stdout = await this.process.execute(pythonOnnxWorkerInputJson(request));
    return pythonOnnxWorkerOutputFromJson(stdout);
  }
}
