import {createReadStream, createWriteStream} from "node:fs";
import {mkdir, rm} from "node:fs/promises";
import {createHash} from "node:crypto";
import path from "node:path";
import {Readable} from "node:stream";
import {pipeline} from "node:stream/promises";
import {type ModelArtifactPublication, type ModelArtifactPublisher} from "../../domain/repositories/model-artifact-publisher.js";
import {modelBundleFor} from "../model-artifact-bundle.js";
import {type PublicationFile, publicationFiles} from "../model-artifact-publication-files.js";

/** Speichert Modellversionen unter dem Runtime-Verzeichnis, im selben Layout wie der globale Modellspeicher. */
export class LocalModelArtifactPublisher implements ModelArtifactPublisher {
  constructor(private readonly rootDirectory: string) {}

  async publish(publication: ModelArtifactPublication): Promise<void> {
    for (const file of publicationFiles(publication)) await this.publishFile(file);
  }

  async remove(reference: ModelArtifactPublication["reference"]): Promise<void> {
    await Promise.all(modelBundleFor(reference).files.map((file) =>
      rm(path.join(this.rootDirectory, file.storePath), {force: true})));
  }

  private async publishFile(file: PublicationFile): Promise<void> {
    const destination = path.join(this.rootDirectory, file.storagePath);
    await mkdir(path.dirname(destination), {recursive: true});
    try {
      await pipeline(Readable.from(file.content), createWriteStream(destination, {flags: "wx"}));
    } catch (error) {
      if (!isAlreadyPublished(error)) throw publishError(error);
      await ensureMatchingArtifact(destination, file.sha256);
    }
  }
}

async function ensureMatchingArtifact(filePath: string, expectedSha256: string): Promise<void> {
  const hash = createHash("sha256");
  for await (const chunk of createReadStream(filePath)) hash.update(chunk as Buffer);
  if (hash.digest("hex") !== expectedSha256.toLowerCase()) {
    throw new Error("Diese lokale Modellversion existiert bereits mit anderem Inhalt.");
  }
}

function publishError(error: unknown): Error {
  return error instanceof Error ? error : new Error("Das lokale Modellartefakt konnte nicht gespeichert werden.");
}

function isAlreadyPublished(error: unknown): boolean {
  return typeof error === "object" && error !== null && "code" in error && error.code === "EEXIST";
}
