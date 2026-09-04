import {type ModelArtifactReference} from "../domain/entities/model-artifact-reference.js";
import {type ModelArtifactReader} from "../domain/repositories/model-artifact-reader.js";

export class CachingModelArtifactReader implements ModelArtifactReader {
  private readonly entries = new Map<string, Promise<Uint8Array>>();

  constructor(
    private readonly delegate: ModelArtifactReader,
    private readonly maximumEntries: number,
  ) {
    if (!Number.isSafeInteger(maximumEntries) || maximumEntries < 1) {
      throw new Error("Die maximale Anzahl gecachter Modellartefakte ist ungültig.");
    }
  }

  read(reference: ModelArtifactReference): Promise<Uint8Array> {
    const key = artifactKey(reference);
    const existing = this.entries.get(key);
    if (existing !== undefined) return this.touch(key, existing);
    return this.load(key, reference);
  }

  private touch(key: string, content: Promise<Uint8Array>): Promise<Uint8Array> {
    this.entries.delete(key);
    this.entries.set(key, content);
    return content;
  }

  private load(key: string, reference: ModelArtifactReference): Promise<Uint8Array> {
    const content = this.delegate.read(reference).catch((error: unknown) => {
      this.entries.delete(key);
      throw error;
    });
    this.entries.set(key, content);
    this.evictExcessEntries();
    return content;
  }

  private evictExcessEntries(): void {
    while (this.entries.size > this.maximumEntries) {
      const key = this.entries.keys().next().value;
      if (key === undefined) return;
      this.entries.delete(key);
    }
  }
}

function artifactKey(reference: ModelArtifactReference): string {
  return `${reference.artifactId}:${reference.versionId}:${reference.sha256}`;
}
