import {PrepareModelInputs} from "../domain/usecases/prepare-model-inputs.js";
import {RunModelInference} from "../domain/usecases/run-model-inference.js";
import {RunModelInferenceWithSources} from "../domain/usecases/run-model-inference-with-sources.js";
import {type ModelCatalog} from "../domain/repositories/model-catalog.js";
import {FirestoreModelCatalog} from "./firebase/firestore-model-catalog.js";
import {HttpPythonInferenceSidecar} from "./http-python-inference-sidecar.js";
import {MlServiceHttp} from "./ml-service-http.js";
import {LocalFileModelCatalog} from "./local/local-file-model-catalog.js";
import {HttpPythonModelInputTransformer} from "./local/http-python-model-input-transformer.js";
import {GlobalModelBundleSources, LocalDirectoryModelBundleSources, type ModelBundleSources} from "./model-bundle-sources.js";
import {SidecarOnnxInferenceRuntime} from "./python-inference-sidecar.js";

/**
 * Der Inferenzdienst (Cloud Run) spricht wie die Runtime mit dem ML-Dienst; der läuft im selben Container.
 * Cloud: Katalog aus Firestore, Dateien aus dem globalen Modellspeicher. Lokal: beides aus einem Verzeichnis.
 */
export function createModelInferenceService(): RunModelInferenceWithSources {
  if (process.env.MODEL_INFERENCE_MODE === "local") {
    const rootDirectory = requiredEnvironment("LOCAL_RUNTIME_ROOT");
    return createInference(new LocalFileModelCatalog(`${rootDirectory}/model-catalog`), new LocalDirectoryModelBundleSources(rootDirectory));
  }
  return createInference(new FirestoreModelCatalog(), new GlobalModelBundleSources());
}

function createInference(catalog: ModelCatalog, sources: ModelBundleSources): RunModelInferenceWithSources {
  // Der ML-Dienst läuft im selben Pod für genau diesen Nutzer (ML_TENANCY=off): keine Anmeldung nötig.
  const mlService = new MlServiceHttp(requiredEnvironment("PYTHON_INFERENCE_SIDECAR_URL"));
  return new RunModelInferenceWithSources(
    catalog,
    new PrepareModelInputs(new HttpPythonModelInputTransformer(mlService)),
    new RunModelInference(new SidecarOnnxInferenceRuntime(new HttpPythonInferenceSidecar(mlService), sources)),
  );
}

function requiredEnvironment(name: string): string {
  const value = process.env[name];
  if (value === undefined || value.trim().length === 0) throw new Error(`${name} fehlt.`);
  return value;
}
