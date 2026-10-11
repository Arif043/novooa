import {type RuntimeExecutor} from "../../../../db/database.js";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {type ModelArtifactPrefetcher} from "../../domain/repositories/model-artifact-prefetcher.js";
import {CacheSystemModel} from "../../domain/usecases/cache-system-model.js";
import {HttpPythonInferenceSidecar} from "../http-python-inference-sidecar.js";
import {RuntimeModelBundleSources} from "../model-bundle-sources.js";
import {SidecarOnnxInferenceRuntime} from "../python-inference-sidecar.js";
import {ModelCacheJobs} from "./model-cache-jobs.js";
import {PythonModelContractValidator, UnavailablePythonModelContractValidator} from "./python-model-contract-validator.js";
import {type RuntimeSystemModelCatalog} from "./runtime-system-model-catalog.js";
import {SQLiteModelCatalog} from "./sqlite-model-catalog.js";

export type LocalModelCache = {
  jobs: ModelCacheJobs;
  cacheSystemModel: CacheSystemModel;
};

export type LocalModelCacheOptions = {
  database: RuntimeExecutor;
  runtimeRoot: string;
  teamId: string;
  systemModelCatalog: RuntimeSystemModelCatalog;
  notifier: {publish(topic: string): void};
  logger: ApplicationLogger;
};

/**
 * Ein Cache je Arbeitsbereich, geteilt von Routen (Hintergrund-Vorladen) und Inferenzpfad (Nachladen).
 * Katalogmodelle werden nicht in die Runtime kopiert: Der ML-Dienst holt sie aus dem globalen Modellspeicher.
 */
export function createLocalModelCache(options: LocalModelCacheOptions): LocalModelCache {
  const sidecarUrl = process.env.PYTHON_INFERENCE_SIDECAR_URL?.trim();
  const cacheSystemModel = new CacheSystemModel(
    new SQLiteModelCatalog(options.database),
    options.systemModelCatalog,
    sidecarUrl ? new PythonModelContractValidator(sidecarUrl) : new UnavailablePythonModelContractValidator(),
    sidecarUrl ? prefetcherFor(sidecarUrl, options.runtimeRoot) : unavailablePrefetcher,
  );
  return {
    cacheSystemModel,
    jobs: new ModelCacheJobs(options.teamId, cacheSystemModel, options.notifier, options.logger),
  };
}

function prefetcherFor(sidecarUrl: string, runtimeRoot: string): ModelArtifactPrefetcher {
  return new SidecarOnnxInferenceRuntime(new HttpPythonInferenceSidecar(sidecarUrl), new RuntimeModelBundleSources(runtimeRoot));
}

const unavailablePrefetcher: ModelArtifactPrefetcher = {
  prefetch: () => Promise.reject(new Error("Die lokale Python-Inferenz ist nicht verfügbar.")),
};
