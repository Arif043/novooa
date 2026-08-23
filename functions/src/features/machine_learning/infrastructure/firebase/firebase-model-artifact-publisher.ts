import {Readable, type Writable} from "node:stream";
import {pipeline} from "node:stream/promises";
import {type ModelArtifactPublication, type ModelArtifactPublisher} from "../../domain/repositories/model-artifact-publisher.js";
import {modelArtifactStoragePathFor} from "../model-artifact-storage-path.js";
import {getDefaultStorageBucket} from "../../../files/infrastructure/firebase/firebase-storage.js";

type ArtifactWriteOptions = {
  resumable: boolean;
  preconditionOpts: {ifGenerationMatch: number};
  metadata: {contentType: string; metadata: Record<string, string>};
};

interface ArtifactBucket {
  file(path: string): {createWriteStream(options: ArtifactWriteOptions): Writable};
}

export class FirebaseModelArtifactPublisher implements ModelArtifactPublisher {
  constructor(private readonly bucket: ArtifactBucket = getDefaultStorageBucket()) {}

  async publish(publication: ModelArtifactPublication): Promise<void> {
    const file = this.bucket.file(modelArtifactStoragePathFor(publication.reference));
    try {
      await pipeline(Readable.from(publication.content), file.createWriteStream(writeOptions(publication)));
    } catch (error) {
      throw publishError(error);
    }
  }
}

function writeOptions(publication: ModelArtifactPublication): ArtifactWriteOptions {
  const reference = publication.reference;
  return {
    resumable: true,
    preconditionOpts: {ifGenerationMatch: 0},
    metadata: {
      contentType: reference.contentType,
      metadata: {sha256: reference.sha256, sizeBytes: String(reference.sizeBytes)},
    },
  };
}

function publishError(error: unknown): Error {
  if (errorCode(error) === 412) return new Error("Diese Modellversion wurde bereits veröffentlicht.");
  return error instanceof Error ? error : new Error("Das Modellartefakt konnte nicht hochgeladen werden.");
}

function errorCode(error: unknown): number | undefined {
  if (error === null || typeof error !== "object" || !("code" in error)) return undefined;
  return typeof error.code === "number" ? error.code : undefined;
}
