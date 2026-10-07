import {type CacheSystemModel} from "../../domain/usecases/cache-system-model.js";
import {SelfCachingModelCatalog} from "./self-caching-model-catalog.js";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {PrepareModelInputs} from "../../domain/usecases/prepare-model-inputs.js";
import {RunModelInferenceWithSources} from "../../domain/usecases/run-model-inference-with-sources.js";
import {RunModelInference} from "../../domain/usecases/run-model-inference.js";
import {CachingModelArtifactReader} from "../caching-model-artifact-reader.js";
import {HttpPythonInferenceSidecar, SidecarOnnxInferenceRuntime} from "../python-inference-sidecar.js";
import {HttpPythonModelInputTransformer} from "./http-python-model-input-transformer.js";
import {LocalModelArtifactReader} from "./local-model-artifact-reader.js";
import {SQLiteModelCatalog} from "./sqlite-model-catalog.js";

export function createLocalSidecarModelInference(
  database: RuntimeExecutor,
  runtimeRoot: string,
  sidecarUrl: string,
  cacheSystemModel?: CacheSystemModel,
): RunModelInferenceWithSources {
  const artifactReader = new CachingModelArtifactReader(
    new LocalModelArtifactReader(runtimeRoot),
    4,
  );
  const runtime = new SidecarOnnxInferenceRuntime(
    new HttpPythonInferenceSidecar(sidecarUrl),
  );
  return new RunModelInferenceWithSources(
    // Mit Modell-Cache lädt ein Lauf fehlende Katalogmodelle vor der Ausführung nach.
    cacheSystemModel === undefined
      ? new SQLiteModelCatalog(database)
      : new SelfCachingModelCatalog(new SQLiteModelCatalog(database), cacheSystemModel),
    new PrepareModelInputs(new HttpPythonModelInputTransformer(sidecarUrl)),
    new RunModelInference(artifactReader, runtime),
  );
}
