import path from "node:path";
import { PublishSystemModel } from "../../domain/usecases/publish-system-model.js";
import { LocalFileModelCatalog } from "../local/local-file-model-catalog.js";
import { LocalModelArtifactPublisher } from "../local/local-model-artifact-publisher.js";
import { LocalPythonProcess } from "../local/local-python-process.js";
import { PythonOnnxModelValidator } from "../python-onnx-model-validator.js";
import { type ModelPublishCommandDependencies } from "./model-publish-command.js";
import { type LocalModelInstallOptions } from "./local-model-install-options.js";

export function localModelInstallDependencies(
  options: LocalModelInstallOptions,
): ModelPublishCommandDependencies {
  return {
    publisher: new PublishSystemModel(
      new LocalModelArtifactPublisher(options.runtimeRoot),
      new LocalFileModelCatalog(
        path.join(options.runtimeRoot, "model-catalog"),
      ),
    ),
    onnxValidator: new PythonOnnxModelValidator(
      new LocalPythonProcess({
        pythonExecutable: options.pythonExecutable,
        workerScriptPath: onnxValidationWorkerPath(),
      }),
    ),
  };
}

function onnxValidationWorkerPath(): string {
  return path.resolve(
    __dirname,
    "../../../../../../local-runtime/python/onnx_validation_worker.py",
  );
}
