import {type ModelCatalogEntry, validateModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelArtifactPrefetcher} from "../repositories/model-artifact-prefetcher.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {type ModelContractCheck, type SystemModelSource} from "../repositories/system-model-source.js";

/** Das Modell steht nicht im globalen Katalog (oder ist dort nicht mehr verfügbar). */
export class SystemModelNotFoundError extends Error {
  constructor(modelId: string) {
    super(`Das Modell „${modelId}“ ist im Modellkatalog nicht verfügbar.`);
    this.name = "SystemModelNotFoundError";
  }
}

/**
 * Nimmt ein Modell des globalen Katalogs in den Teamkatalog auf: Ist es schon dort, bleibt es dabei;
 * sonst wird der Vertrag geprüft, das Modell beim ML-Dienst vorgeladen und als Teameintrag gespeichert.
 * Die Dateien bleiben im globalen Modellspeicher. Gleichzeitige Anfragen teilen sich einen Vorgang.
 */
export class CacheSystemModel {
  private readonly downloads = new Map<string, Promise<ModelCatalogEntry>>();

  constructor(
    private readonly catalog: ModelCatalog,
    private readonly source: SystemModelSource,
    private readonly contractCheck: ModelContractCheck,
    private readonly prefetcher: ModelArtifactPrefetcher,
  ) {}

  async execute(teamId: string, modelId: string): Promise<ModelCatalogEntry> {
    const cached = await this.catalog.findAvailableFor(teamId, modelId);
    if (cached !== null) return cached;
    const key = `${teamId}/${modelId}`;
    const running = this.downloads.get(key);
    if (running !== undefined) return running;
    const download = this.download(teamId, modelId).finally(() => this.downloads.delete(key));
    this.downloads.set(key, download);
    return download;
  }

  private async download(teamId: string, modelId: string): Promise<ModelCatalogEntry> {
    const model = await this.source.find(modelId);
    if (model === null) throw new SystemModelNotFoundError(modelId);
    await this.contractCheck.validate(model.entry.contract);
    const entry: ModelCatalogEntry = {...model.entry, scope: {type: "team", teamId}, origin: "catalog"};
    validateModelCatalogEntry(entry);
    await this.prefetcher.prefetch(entry);
    await this.catalog.save(entry);
    return entry;
  }
}
