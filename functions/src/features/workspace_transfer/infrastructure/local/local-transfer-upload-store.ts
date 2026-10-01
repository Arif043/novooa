import {randomUUID} from "node:crypto";
import {once} from "node:events";
import {createWriteStream} from "node:fs";
import {mkdir, rm} from "node:fs/promises";
import path from "node:path";
import {finished} from "node:stream/promises";

export type StagedTransferUpload = {id: string; path: string; stagedAt: number};

export class TransferUploadTooLargeError extends Error {
  constructor() {
    super("Die Export-Datei überschreitet die maximal erlaubte Größe von 4 GiB.");
  }
}

const defaultMaximumBytes = 4 * 1024 * 1024 * 1024;
const defaultLifetimeMs = 30 * 60 * 1000;

/** Hält hochgeladene Exporte bis zur Bestätigung des Imports vor. */
export class LocalTransferUploadStore {
  private readonly uploads = new Map<string, StagedTransferUpload>();

  constructor(
    private readonly runtimeRoot: string,
    private readonly maximumBytes = defaultMaximumBytes,
    private readonly lifetimeMs = defaultLifetimeMs,
    private readonly now: () => number = Date.now,
  ) {}

  async stage(content: AsyncIterable<Uint8Array>, contentLength: number | null): Promise<StagedTransferUpload> {
    await this.discardExpired();
    if (contentLength !== null && contentLength > this.maximumBytes) throw new TransferUploadTooLargeError();
    const upload = {id: randomUUID(), path: this.pathFor(randomUUID()), stagedAt: this.now()};
    await mkdir(path.dirname(upload.path), {recursive: true});
    await this.write(content, upload.path);
    this.uploads.set(upload.id, upload);
    return upload;
  }

  /** Entnimmt den Upload, damit er nicht parallel zweimal importiert wird. */
  async take(id: string): Promise<StagedTransferUpload | undefined> {
    await this.discardExpired();
    const upload = this.uploads.get(id);
    this.uploads.delete(id);
    return upload;
  }

  async discard(upload: StagedTransferUpload | undefined): Promise<void> {
    if (upload === undefined) return;
    this.uploads.delete(upload.id);
    await rm(upload.path, {force: true});
  }

  private async discardExpired(): Promise<void> {
    const expired = [...this.uploads.values()].filter((upload) => this.now() - upload.stagedAt > this.lifetimeMs);
    for (const upload of expired) await this.discard(upload);
  }

  private async write(content: AsyncIterable<Uint8Array>, destination: string): Promise<void> {
    const stream = createWriteStream(destination, {flags: "wx"});
    let sizeBytes = 0;
    try {
      for await (const chunk of content) {
        sizeBytes += chunk.length;
        if (sizeBytes > this.maximumBytes) throw new TransferUploadTooLargeError();
        if (!stream.write(chunk)) await once(stream, "drain");
      }
      stream.end();
      await finished(stream);
    } catch (error) {
      stream.destroy();
      await rm(destination, {force: true});
      throw error;
    }
  }

  private pathFor(fileId: string): string {
    return path.join(this.runtimeRoot, "transfer-imports", `${fileId}.zip`);
  }
}
