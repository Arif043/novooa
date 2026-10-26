import {type ModelArtifactReference} from "../entities/model-artifact-reference.js";
import {type ModelCatalogEntry, validateModelCatalogEntry} from "../entities/model-catalog-entry.js";
import {
  type ModelArtifactPublication,
  type ModelArtifactPublisher,
} from "../repositories/model-artifact-publisher.js";
import {type ModelTagVocabularySource} from "../repositories/model-tag-vocabulary-source.js";
import {type SystemModelRegistry} from "../repositories/system-model-registry.js";
import {requirePublicationMatchesEntry} from "../services/artifact-publication-match.js";

export type PublishSystemModelRequest = {
  entry: ModelCatalogEntry;
  artifact: ModelArtifactPublication;
  /** Erlaubt, einen Eintrag mit einer anderen Artefaktversion zu ersetzen. */
  replaceVersion?: boolean;
};

/** Unter der Modell-ID steht bereits eine andere Version; sie zu ersetzen, muss ausdrücklich gewollt sein. */
export class SystemModelVersionConflictError extends Error {
  constructor(modelId: string, published: ModelArtifactReference, requested: ModelArtifactReference) {
    super(
      `Das Systemmodell „${modelId}“ ist bereits als ${versionOf(published)} veröffentlicht; `
      + `${versionOf(requested)} würde den Eintrag für alle Runtimes ersetzen.`,
    );
    this.name = "SystemModelVersionConflictError";
  }
}

export class PublishSystemModel {
  constructor(
    private readonly artifactPublisher: ModelArtifactPublisher,
    private readonly registry: SystemModelRegistry,
    private readonly tagVocabulary: ModelTagVocabularySource,
  ) {}

  /** Prüft die Veröffentlichung vollständig, ohne Dateien oder Katalog zu verändern. */
  async check(request: PublishSystemModelRequest): Promise<void> {
    validatePublication(request);
    (await this.tagVocabulary.load()).requireKnown(request.entry.tags);
    const published = await this.registry.findSystemEntry(request.entry.id);
    if (published === null || request.replaceVersion === true) return;
    if (!sameVersion(published.artifactReference, request.entry.artifactReference)) {
      throw new SystemModelVersionConflictError(request.entry.id, published.artifactReference, request.entry.artifactReference);
    }
  }

  async execute(request: PublishSystemModelRequest): Promise<ModelCatalogEntry> {
    await this.check(request);
    await this.artifactPublisher.publish(request.artifact);
    await this.registry.save(request.entry);
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

function sameVersion(left: ModelArtifactReference, right: ModelArtifactReference): boolean {
  return left.artifactId === right.artifactId && left.versionId === right.versionId;
}

function versionOf(reference: ModelArtifactReference): string {
  return `${reference.artifactId}@${reference.versionId}`;
}
