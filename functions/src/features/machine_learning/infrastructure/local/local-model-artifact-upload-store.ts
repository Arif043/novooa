import {createHash} from "node:crypto";
import {createReadStream, createWriteStream} from "node:fs";
import {mkdir, rm, statfs} from "node:fs/promises";
import {once} from "node:events";
import {finished} from "node:stream/promises";
import path from "node:path";
import {LocalModelCatalogRequestError} from "./local-model-catalog-errors.js";

export type StagedModelArtifact = {
  path: string;
  sizeBytes: number;
  sha256: string;
};

export type FreeBytes = (directory: string) => Promise<number>;

/**
 * Zwischenablage eines Imports: Modell und Gewichtsdateien liegen unter ihrem Namen in einem Ordner je Import.
 * Eine feste Größengrenze gibt es nur, wenn sie konfiguriert ist; sonst begrenzt der freie Platz.
 */
export class LocalModelArtifactUploadStore {
  constructor(
    private readonly runtimeRoot: string,
    private readonly maximumFileBytes: number | null = null,
    private readonly freeBytes: FreeBytes = freeBytesOf,
  ) {}

  async stage(importId: string, fileName: string, content: AsyncIterable<Uint8Array>, contentLength: number | null): Promise<StagedModelArtifact> {
    const destination = path.join(this.directoryFor(importId), fileName);
    await mkdir(path.dirname(destination), {recursive: true});
    await this.requireSpace(destination, contentLength);
    return writeArtifact(content, destination, this.maximumFileBytes);
  }

  contentFor(staged: StagedModelArtifact): AsyncIterable<Uint8Array> {
    return createReadStream(staged.path);
  }

  async discard(importId: string): Promise<void> {
    await rm(this.directoryFor(importId), {recursive: true, force: true});
  }

  private async requireSpace(destination: string, contentLength: number | null): Promise<void> {
    if (contentLength === null) return;
    if (this.maximumFileBytes !== null && contentLength > this.maximumFileBytes) throw tooLarge(this.maximumFileBytes);
    if (contentLength > await this.freeBytes(path.dirname(destination))) {
      throw new LocalModelCatalogRequestError("Für diese Modelldatei ist nicht genug Speicherplatz frei.");
    }
  }

  private directoryFor(importId: string): string {
    return path.join(this.runtimeRoot, "model-imports", importId);
  }
}

async function freeBytesOf(directory: string): Promise<number> {
  const stats = await statfs(directory);
  return stats.bavail * stats.bsize;
}

async function writeArtifact(content: AsyncIterable<Uint8Array>, destination: string, maximum: number | null): Promise<StagedModelArtifact> {
  const hash = createHash("sha256");
  const stream = createWriteStream(destination, {flags: "w"});
  let sizeBytes = 0;
  try {
    for await (const chunk of content) {
      const bytes = Buffer.from(chunk);
      sizeBytes += bytes.length;
      if (maximum !== null && sizeBytes > maximum) throw tooLarge(maximum);
      hash.update(bytes);
      if (!stream.write(bytes)) await once(stream, "drain");
    }
    stream.end();
    await finished(stream);
    if (sizeBytes === 0) throw new LocalModelCatalogRequestError("Die hochgeladene Datei ist leer.");
    return {path: destination, sizeBytes, sha256: hash.digest("hex")};
  } catch (error) {
    stream.destroy();
    await rm(destination, {force: true});
    throw error;
  }
}

function tooLarge(maximum: number): Error {
  return new LocalModelCatalogRequestError(`Die Datei überschreitet die erlaubte Größe von ${maximum} Bytes.`);
}

/** Optionale Obergrenze je Datei aus `MODEL_ARTIFACT_MAX_BYTES`; ohne Wert begrenzt nur der freie Platz. */
export function maximumArtifactBytesFromEnvironment(environment = process.env): number | null {
  const value = environment.MODEL_ARTIFACT_MAX_BYTES?.trim();
  if (!value) return null;
  const bytes = Number(value);
  if (!Number.isSafeInteger(bytes) || bytes <= 0) throw new Error("MODEL_ARTIFACT_MAX_BYTES ist ungültig.");
  return bytes;
}
