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
): RunModelInferenceWithSources {
  const artifactReader = new CachingModelArtifactReader(
    new LocalModelArtifactReader(runtimeRoot),
    4,
  );
  const runtime = new SidecarOnnxInferenceRuntime(
    new HttpPythonInferenceSidecar(sidecarUrl),
  );
  return new RunModelInferenceWithSources(
    new SQLiteModelCatalog(database),
    new PrepareModelInputs(new HttpPythonModelInputTransformer(sidecarUrl)),
    new RunModelInference(artifactReader, runtime),
  );
}
