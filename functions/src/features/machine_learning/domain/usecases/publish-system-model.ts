import {type ModelCatalogEntry, validateModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {
  type ModelArtifactPublication,
  type ModelArtifactPublisher,
} from "../repositories/model-artifact-publisher.js";
import {type ModelCatalog} from "../repositories/model-catalog.js";
import {requirePublicationMatchesEntry} from "../services/artifact-publication-match.js";

export type PublishSystemModelRequest = {
  entry: ModelCatalogEntry;
  artifact: ModelArtifactPublication;
};

export class PublishSystemModel {
  constructor(
    private readonly artifactPublisher: ModelArtifactPublisher,
    private readonly catalog: ModelCatalog,
  ) {}

  async execute(request: PublishSystemModelRequest): Promise<ModelCatalogEntry> {
    validatePublication(request);
    await this.artifactPublisher.publish(request.artifact);
    await this.catalog.save(request.entry);
    return request.entry;
  }
}

function validatePublication(request: PublishSystemModelRequest): void {
  validateModelCatalogEntry(request.entry);
  if (request.entry.scope.type !== "system") {
    throw new Error("Der Betreiber-Publisher darf nur Systemmodelle veröffentlichen.");
  }
  requirePublicationMatchesEntry(request.entry, request.artifact);
}
