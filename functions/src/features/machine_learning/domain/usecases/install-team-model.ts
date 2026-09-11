import {type ModelCatalogEntry, validateModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {type ModelArtifactPublication, type ModelArtifactPublisher} from "../repositories/model-artifact-publisher.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";

export type InstallTeamModelRequest = {
  entry: ModelCatalogEntry;
  artifact: ModelArtifactPublication;
};

export class InstallTeamModel {
  constructor(
    private readonly artifactPublisher: ModelArtifactPublisher,
    private readonly catalog: ModelCatalog,
  ) {}

  async execute(request: InstallTeamModelRequest): Promise<ModelCatalogEntry> {
    validateRequest(request);
    await this.artifactPublisher.publish(request.artifact);
    await this.catalog.save(request.entry);
    return request.entry;
  }
}

function validateRequest(request: InstallTeamModelRequest): void {
  validateModelCatalogEntry(request.entry);
  if (request.entry.scope.type !== "team") {
    throw new Error("Lokale Modellimporte müssen einem Team zugeordnet sein.");
  }
  if (JSON.stringify(request.entry.artifactReference) !== JSON.stringify(request.artifact.reference)) {
    throw new Error("Artefakt und Katalogeintrag referenzieren unterschiedliche Modellversionen.");
  }
}
