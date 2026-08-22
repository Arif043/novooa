import {PrepareModelInputs} from "../../domain/usecases/prepare-model-inputs.js";
import {RunModelInference} from "../../domain/usecases/run-model-inference.js";
import {RunModelInferenceWithSources} from "../../domain/usecases/run-model-inference-with-sources.js";
import {FirebaseModelArtifactReader} from "../firebase/firebase-model-artifact-reader.js";
import {FirestoreModelCatalog} from "../firebase/firestore-model-catalog.js";
import {LocalOnnxInferenceRuntime} from "../local/local-onnx-inference-runtime.js";
import {LocalPythonModelInputTransformer} from "../local/local-python-model-input-transformer.js";
import {LocalPythonOnnxWorker} from "../local/local-python-onnx-worker.js";
import {LocalPythonProcess} from "../local/local-python-process.js";

export function createCloudRunModelInference(): RunModelInferenceWithSources {
  const pythonExecutable = process.env.PYTHON_EXECUTABLE ?? "python3";
  const transformer = new LocalPythonModelInputTransformer(new LocalPythonProcess({
    pythonExecutable,
    workerScriptPath: requiredEnvironment("INPUT_TRANSFORM_WORKER_PATH"),
  }));
  const runtime = new LocalOnnxInferenceRuntime(new LocalPythonOnnxWorker(new LocalPythonProcess({
    pythonExecutable,
    workerScriptPath: requiredEnvironment("ONNX_WORKER_PATH"),
  })));
  return new RunModelInferenceWithSources(
    new FirestoreModelCatalog(),
    new PrepareModelInputs(transformer),
    new RunModelInference(new FirebaseModelArtifactReader(), runtime),
  );
}

function requiredEnvironment(name: string): string {
  const value = process.env[name];
  if (value === undefined || value.trim().length === 0) throw new Error(`${name} fehlt.`);
  return value;
}
