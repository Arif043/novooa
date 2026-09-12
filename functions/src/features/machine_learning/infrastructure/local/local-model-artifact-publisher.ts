import {createWriteStream} from "node:fs";
import {mkdir, readFile, rm} from "node:fs/promises";
import {createHash} from "node:crypto";
import path from "node:path";
import {Readable} from "node:stream";
import {pipeline} from "node:stream/promises";
import {type ModelArtifactPublication, type ModelArtifactPublisher} from "../../domain/repositories/model-artifact-publisher.js";
import {modelArtifactStoragePathFor} from "../model-artifact-storage-path.js";

export class LocalModelArtifactPublisher implements ModelArtifactPublisher {
  constructor(private readonly rootDirectory: string) {}

  async publish(publication: ModelArtifactPublication): Promise<void> {
    const destination = path.join(this.rootDirectory, modelArtifactStoragePathFor(publication.reference));
    await mkdir(path.dirname(destination), {recursive: true});
    try {
      await pipeline(Readable.from(publication.content), createWriteStream(destination, {flags: "wx"}));
    } catch (error) {
      if (isAlreadyPublished(error)) {
        await ensureMatchingArtifact(destination, publication.reference.sha256);
        return;
      }
      throw publishError(error);
    }
  }

  async remove(reference: ModelArtifactPublication["reference"]): Promise<void> {
    const destination = path.join(this.rootDirectory, modelArtifactStoragePathFor(reference));
    await rm(destination, {force: true});
  }
}

async function ensureMatchingArtifact(path: string, expectedSha256: string): Promise<void> {
  const content = await readFile(path);
  const actualSha256 = createHash("sha256").update(content).digest("hex");
  if (actualSha256 !== expectedSha256) {
    throw new Error("Diese lokale Modellversion existiert bereits mit anderem Inhalt.");
  }
}

function publishError(error: unknown): Error {
  if (isAlreadyPublished(error)) return new Error("Diese lokale Modellversion ist bereits installiert.");
  return error instanceof Error ? error : new Error("Das lokale Modellartefakt konnte nicht gespeichert werden.");
}

function isAlreadyPublished(error: unknown): boolean {
  return typeof error === "object" && error !== null && "code" in error && error.code === "EEXIST";
}
