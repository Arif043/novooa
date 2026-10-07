import {type ModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {type ModelContractCheck, type SystemModelSource} from "../repositories/system-model-source.js";
import {type InstallTeamModel} from "./install-team-model.js";

/** Das Modell steht nicht im globalen Katalog (oder ist dort nicht mehr verfügbar). */
export class SystemModelNotFoundError extends Error {
  constructor(modelId: string) {
    super(`Das Modell „${modelId}“ ist im Modellkatalog nicht verfügbar.`);
    this.name = "SystemModelNotFoundError";
  }
}

/**
 * Hält ein Modell des globalen Katalogs lokal vor: Ist es schon im Teamkatalog, bleibt es dabei;
 * sonst wird es geladen, geprüft und als gecachter Teameintrag gespeichert. Gleichzeitige
 * Anfragen für dasselbe Modell teilen sich einen Download.
 */
export class CacheSystemModel {
  private readonly downloads = new Map<string, Promise<ModelCatalogEntry>>();

  constructor(
    private readonly catalog: ModelCatalog,
    private readonly source: SystemModelSource,
    private readonly contractCheck: ModelContractCheck,
    private readonly installer: InstallTeamModel,
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
    const artifact = await model.fetchArtifact();
    return this.installer.execute({
      entry: {...model.entry, scope: {type: "team", teamId}, origin: "catalog"},
      artifact,
    });
  }
}
