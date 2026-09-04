import {PrepareModelInputs} from "../domain/usecases/prepare-model-inputs.js";
import {RunModelInference} from "../domain/usecases/run-model-inference.js";
import {RunModelInferenceWithSources} from "../domain/usecases/run-model-inference-with-sources.js";
import {type ModelArtifactReader} from "../domain/repositories/model-artifact-reader.js";
import {type ModelCatalog} from "../domain/repositories/model-catalog.js";
import {FirebaseModelArtifactReader} from "./firebase/firebase-model-artifact-reader.js";
import {CachingModelArtifactReader} from "./caching-model-artifact-reader.js";
import {FirestoreModelCatalog} from "./firebase/firestore-model-catalog.js";
import {LocalOnnxInferenceRuntime} from "./local/local-onnx-inference-runtime.js";
import {LocalFileModelCatalog} from "./local/local-file-model-catalog.js";
import {LocalModelArtifactReader} from "./local/local-model-artifact-reader.js";
import {LocalPythonModelInputTransformer} from "./local/local-python-model-input-transformer.js";
import {LocalPythonOnnxWorker} from "./local/local-python-onnx-worker.js";
import {LocalPythonProcess} from "./local/local-python-process.js";
import {HttpPythonInferenceSidecar, SidecarOnnxInferenceRuntime} from "./python-inference-sidecar.js";

export function createModelInferenceService(): RunModelInferenceWithSources {
  if (process.env.MODEL_INFERENCE_MODE === "local") return createLocalModelInference();
  return createCloudRunModelInference();
}

function createCloudRunModelInference(): RunModelInferenceWithSources {
  return createInference(new FirestoreModelCatalog(), new FirebaseModelArtifactReader());
}

function createLocalModelInference(): RunModelInferenceWithSources {
  const rootDirectory = requiredEnvironment("LOCAL_RUNTIME_ROOT");
  return createInference(
    new LocalFileModelCatalog(`${rootDirectory}/model-catalog`),
    new LocalModelArtifactReader(rootDirectory),
  );
}

function createInference(
  catalog: ModelCatalog,
  sourceArtifactReader: ModelArtifactReader,
): RunModelInferenceWithSources {
  const artifactReader = new CachingModelArtifactReader(sourceArtifactReader, artifactCacheEntries());
  const transformer = new LocalPythonModelInputTransformer(new LocalPythonProcess({
    pythonExecutable: process.env.PYTHON_EXECUTABLE ?? "python3",
    workerScriptPath: requiredEnvironment("INPUT_TRANSFORM_WORKER_PATH"),
  }));
  return new RunModelInferenceWithSources(
    catalog,
    new PrepareModelInputs(transformer),
    new RunModelInference(artifactReader, runtimeForService()),
  );
}

function runtimeForService() {
  const sidecarUrl = process.env.PYTHON_INFERENCE_SIDECAR_URL;
  if (sidecarUrl !== undefined && sidecarUrl.trim().length > 0) {
    return new SidecarOnnxInferenceRuntime(new HttpPythonInferenceSidecar(sidecarUrl));
  }
  return new LocalOnnxInferenceRuntime(new LocalPythonOnnxWorker(new LocalPythonProcess({
    pythonExecutable: process.env.PYTHON_EXECUTABLE ?? "python3",
    workerScriptPath: requiredEnvironment("ONNX_WORKER_PATH"),
  })));
}

function artifactCacheEntries(): number {
  const value = Number(process.env.MODEL_ARTIFACT_CACHE_ENTRIES ?? "4");
  if (!Number.isSafeInteger(value) || value < 1) throw new Error("MODEL_ARTIFACT_CACHE_ENTRIES ist ungültig.");
  return value;
}

function requiredEnvironment(name: string): string {
  const value = process.env[name];
  if (value === undefined || value.trim().length === 0) throw new Error(`${name} fehlt.`);
  return value;
}
