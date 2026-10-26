import path from "node:path";
import {LocalPythonProcess} from "../local/local-python-process.js";
import {PythonOnnxModelValidator} from "../python-onnx-model-validator.js";
import {PythonProcessModelContractValidator} from "../python-process-model-contract-validator.js";
import {type ModelPublishCommandDependencies} from "./model-publish-command.js";

type PythonModelValidators = Pick<ModelPublishCommandDependencies, "contractValidator" | "onnxValidator">;

/** Beide Prüfungen laufen mit den Python-Skripten der Runtime, damit sie dasselbe annehmen wie der ML-Dienst. */
export function pythonModelValidators(pythonExecutable: string): PythonModelValidators {
  return {
    contractValidator: new PythonProcessModelContractValidator(workerProcess(pythonExecutable, "contract_validation_worker.py")),
    onnxValidator: new PythonOnnxModelValidator(workerProcess(pythonExecutable, "onnx_validation_worker.py")),
  };
}

function workerProcess(pythonExecutable: string, scriptName: string): LocalPythonProcess {
  const workerScriptPath = path.resolve(__dirname, "../../../../../../local-runtime/python", scriptName);
  return new LocalPythonProcess({pythonExecutable, workerScriptPath});
}
