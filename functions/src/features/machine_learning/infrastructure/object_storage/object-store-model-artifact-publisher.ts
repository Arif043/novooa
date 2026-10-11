import {type ModelArtifactPublication, type ModelArtifactPublisher} from "../../domain/repositories/model-artifact-publisher.js";
import {type PublicationFile, publicationFiles} from "../model-artifact-publication-files.js";
import {type ModelObjectStore} from "./model-object-store.js";

/**
 * Veröffentlicht Modellversionen im globalen Modellspeicher. Versionen sind unveränderlich:
 * Eine vorhandene Datei mit gleicher Prüfsumme wird übersprungen, eine abweichende ist ein Fehler.
 */
export class ObjectStoreModelArtifactPublisher implements ModelArtifactPublisher {
  constructor(private readonly store: ModelObjectStore) {}

  async publish(publication: ModelArtifactPublication): Promise<void> {
    for (const file of publicationFiles(publication)) await this.publishFile(file);
  }

  private async publishFile(file: PublicationFile): Promise<void> {
    const stored = await this.store.storedSha256(file.storagePath);
    if (stored === file.sha256.toLowerCase()) return;
    if (stored !== null) throw new Error(`${file.storagePath} wurde bereits mit anderem Inhalt veröffentlicht.`);
    await this.store.put(file.storagePath, file.content, {
      contentType: file.contentType, sizeBytes: file.sizeBytes, sha256: file.sha256.toLowerCase(),
    });
  }
}
