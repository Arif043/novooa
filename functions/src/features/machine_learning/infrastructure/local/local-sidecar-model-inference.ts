import {type CacheSystemModel} from "../../domain/usecases/cache-system-model.js";
import {SelfCachingModelCatalog} from "./self-caching-model-catalog.js";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {PrepareModelInputs} from "../../domain/usecases/prepare-model-inputs.js";
import {RunModelInferenceWithSources} from "../../domain/usecases/run-model-inference-with-sources.js";
import {RunModelInference} from "../../domain/usecases/run-model-inference.js";
import {HttpPythonInferenceSidecar} from "../http-python-inference-sidecar.js";
import {RuntimeModelBundleSources} from "../model-bundle-sources.js";
import {SidecarOnnxInferenceRuntime} from "../python-inference-sidecar.js";
import {HttpPythonModelInputTransformer} from "./http-python-model-input-transformer.js";
import {SQLiteModelCatalog} from "./sqlite-model-catalog.js";

export function createLocalSidecarModelInference(
  database: RuntimeExecutor,
  runtimeRoot: string,
  sidecarUrl: string,
  cacheSystemModel?: CacheSystemModel,
): RunModelInferenceWithSources {
  const runtime = new SidecarOnnxInferenceRuntime(
    new HttpPythonInferenceSidecar(sidecarUrl),
    new RuntimeModelBundleSources(runtimeRoot),
  );
  return new RunModelInferenceWithSources(
    // Mit Modell-Cache nimmt ein Lauf fehlende Katalogmodelle vor der Ausführung auf.
    cacheSystemModel === undefined
      ? new SQLiteModelCatalog(database)
      : new SelfCachingModelCatalog(new SQLiteModelCatalog(database), cacheSystemModel),
    new PrepareModelInputs(new HttpPythonModelInputTransformer(sidecarUrl)),
    new RunModelInference(runtime),
  );
}
