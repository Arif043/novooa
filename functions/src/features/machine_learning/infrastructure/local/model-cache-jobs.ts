import {SystemModelNotFoundError, type CacheSystemModel} from "../../domain/usecases/cache-system-model.js";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";

export const modelCacheTopic = "model-cache";

/** Laufende oder gescheiterte Downloads; ein fertiges Modell steht im Katalog und hat keinen Status mehr. */
export type ModelCacheStatus = {
  modelId: string;
  state: "downloading" | "failed";
  message?: string;
};

/**
 * Lädt Modelle des globalen Katalogs im Hintergrund in den Cache des Arbeitsbereichs. Die App
 * erfährt Änderungen über das Realtime-Thema `model-cache` (Status) und `model-catalog` (fertig).
 * Der Status lebt im Speicher; nach einem Neustart zählt nur, was im Katalog steht.
 */
export class ModelCacheJobs {
  private readonly statuses = new Map<string, ModelCacheStatus>();

  constructor(
    private readonly teamId: string,
    private readonly cache: CacheSystemModel,
    private readonly notifier: {publish(topic: string): void},
    private readonly logger: ApplicationLogger,
  ) {}

  /** Startet den Download, falls er nicht schon läuft. */
  start(modelId: string): void {
    if (this.statuses.get(modelId)?.state === "downloading") return;
    this.update({modelId, state: "downloading"});
    void this.cache.execute(this.teamId, modelId).then(
      () => this.finish(modelId),
      (error: unknown) => this.fail(modelId, error),
    );
  }

  list(): ModelCacheStatus[] {
    return [...this.statuses.values()];
  }

  private finish(modelId: string): void {
    this.statuses.delete(modelId);
    this.logger.info("local_model_cache.cached", {modelId, teamId: this.teamId});
    this.notifier.publish(modelCacheTopic);
    this.notifier.publish("model-catalog");
  }

  private fail(modelId: string, error: unknown): void {
    this.logger.exception("local_model_cache.download_failed", error, {modelId, teamId: this.teamId});
    this.update({modelId, state: "failed", message: failureMessage(error)});
  }

  private update(status: ModelCacheStatus): void {
    this.statuses.set(status.modelId, status);
    this.notifier.publish(modelCacheTopic);
  }
}

function failureMessage(error: unknown): string {
  if (error instanceof SystemModelNotFoundError) return error.message;
  return "Das Modell konnte nicht heruntergeladen werden. Bitte versuche es erneut.";
}
