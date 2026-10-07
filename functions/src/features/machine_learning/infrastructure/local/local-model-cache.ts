import path from "node:path";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {CacheSystemModel} from "../../domain/usecases/cache-system-model.js";
import {InstallTeamModel} from "../../domain/usecases/install-team-model.js";
import {CatalogSystemModelSource} from "./catalog-system-model-source.js";
import {HuggingFaceModelArtifactDownloader} from "./hugging-face-model-artifact-downloader.js";
import {LocalModelArtifactPublisher} from "./local-model-artifact-publisher.js";
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

/** Ein Cache je Arbeitsbereich, geteilt von Routen (Hintergrund-Download) und Inferenzpfad (Nachladen). */
export function createLocalModelCache(options: LocalModelCacheOptions): LocalModelCache {
  const sidecarUrl = process.env.PYTHON_INFERENCE_SIDECAR_URL?.trim();
  const downloader = new HuggingFaceModelArtifactDownloader(
    path.join(options.runtimeRoot, "model-cache"), process.env.HF_TOKEN?.trim() || undefined,
  );
  const catalog = new SQLiteModelCatalog(options.database);
  const cacheSystemModel = new CacheSystemModel(
    catalog,
    new CatalogSystemModelSource(options.systemModelCatalog, downloader),
    sidecarUrl ? new PythonModelContractValidator(sidecarUrl) : new UnavailablePythonModelContractValidator(),
    new InstallTeamModel(new LocalModelArtifactPublisher(options.runtimeRoot), catalog),
  );
  return {
    cacheSystemModel,
    jobs: new ModelCacheJobs(options.teamId, cacheSystemModel, options.notifier, options.logger),
  };
}
