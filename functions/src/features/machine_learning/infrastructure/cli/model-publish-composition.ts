import {getApps, initializeApp} from "firebase-admin/app";
import path from "node:path";
import {PublishSystemModel} from "../../domain/usecases/publish-system-model.js";
import {FirestoreModelCatalog} from "../firebase/firestore-model-catalog.js";
import {LocalPythonProcess} from "../local/local-python-process.js";
import {ObjectStoreModelArtifactPublisher} from "../object_storage/object-store-model-artifact-publisher.js";
import {S3ModelObjectStore, s3ModelStoreConfigurationFromEnvironment} from "../object_storage/s3-model-object-store.js";
import {PythonOnnxModelValidator} from "../python-onnx-model-validator.js";
import {type ModelPublishCommandDependencies} from "./model-publish-command.js";
import {type ModelPublishOptions} from "./model-publish-options.js";

/** Dateien in den globalen Modellspeicher (Hetzner Object Storage), Katalogeintrag nach Firestore. */
export function cloudModelPublishDependencies(
  options: ModelPublishOptions,
): ModelPublishCommandDependencies {
  initializeCloudApp(options);
  return {
    publisher: new PublishSystemModel(
      new ObjectStoreModelArtifactPublisher(new S3ModelObjectStore(s3ModelStoreConfigurationFromEnvironment())),
      new FirestoreModelCatalog(),
    ),
    onnxValidator: new PythonOnnxModelValidator(new LocalPythonProcess({
      pythonExecutable: options.pythonExecutable, workerScriptPath: onnxValidationWorkerPath(),
    })),
  };
}

function initializeCloudApp(options: ModelPublishOptions): void {
  if (getApps().length > 0) return;
  initializeApp({projectId: options.projectId});
}

function onnxValidationWorkerPath(): string {
  return path.resolve(__dirname, "../../../../../../local-runtime/python/onnx_validation_worker.py");
}
