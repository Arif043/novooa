import {createHash} from "node:crypto";
import {createReadStream, createWriteStream} from "node:fs";
import {mkdir, rm} from "node:fs/promises";
import {once} from "node:events";
import {finished} from "node:stream/promises";
import path from "node:path";

export type StagedModelArtifact = {
  path: string;
  sizeBytes: number;
  sha256: string;
};

export class LocalModelArtifactUploadStore {
  constructor(
    private readonly runtimeRoot: string,
    private readonly maximumArtifactBytes = 2 * 1024 * 1024 * 1024,
  ) {}

  async stage(
    uploadId: string,
    content: AsyncIterable<Uint8Array>,
    contentLength: number | null,
  ): Promise<StagedModelArtifact> {
    validateContentLength(contentLength, this.maximumArtifactBytes);
    const destination = this.pathFor(uploadId);
    await mkdir(path.dirname(destination), {recursive: true});
    return writeArtifact(content, destination, this.maximumArtifactBytes);
  }

  contentFor(staged: StagedModelArtifact): AsyncIterable<Uint8Array> {
    return createReadStream(staged.path);
  }

  async discard(staged: StagedModelArtifact): Promise<void> {
    await rm(staged.path, {force: true});
  }

  private pathFor(uploadId: string): string {
    return path.join(this.runtimeRoot, "model-imports", uploadId + ".onnx");
  }
}

function validateContentLength(length: number | null, maximum: number): void {
  if (length !== null && length > maximum) {
    throw new Error("Die ONNX-Datei überschreitet die maximal erlaubte Größe von 2 GiB.");
  }
}

async function writeArtifact(
  content: AsyncIterable<Uint8Array>,
  destination: string,
  maximum: number,
): Promise<StagedModelArtifact> {
  const hash = createHash("sha256");
  const stream = createWriteStream(destination, {flags: "wx"});
  let sizeBytes = 0;
  try {
    for await (const chunk of content) {
      const bytes = Buffer.from(chunk);
      sizeBytes += bytes.length;
      if (sizeBytes > maximum) {
        throw new Error("Die ONNX-Datei überschreitet die maximal erlaubte Größe von 2 GiB.");
      }
      hash.update(bytes);
      if (!stream.write(bytes)) await once(stream, "drain");
    }
    stream.end();
    await finished(stream);
    return {path: destination, sizeBytes, sha256: hash.digest("hex")};
  } catch (error) {
    stream.destroy();
    await rm(destination, {force: true});
    throw error;
  }
}
