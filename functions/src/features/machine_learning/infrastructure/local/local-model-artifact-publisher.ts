import {createWriteStream} from "node:fs";
import {mkdir} from "node:fs/promises";
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
      throw publishError(error);
    }
  }
}

function publishError(error: unknown): Error {
  if (typeof error === "object" && error !== null && "code" in error && error.code === "EEXIST") {
    return new Error("Diese lokale Modellversion ist bereits installiert.");
  }
  return error instanceof Error ? error : new Error("Das lokale Modellartefakt konnte nicht gespeichert werden.");
}
