import {type ModelArtifactReference, type ModelArtifactResourceReference} from "../domain/entities/model-artifact-reference.js";
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
    return this.cached(artifactKey(reference), () => this.delegate.read(reference));
  }

  readResource(reference: ModelArtifactReference, resource: ModelArtifactResourceReference): Promise<Uint8Array> {
    if (this.delegate.readResource === undefined) throw new Error("Die Quelle kann Modellressourcen nicht lesen.");
    return this.cached(`${artifactKey(reference)}:resource:${resource.name}:${resource.sha256}`, () => this.delegate.readResource!(reference, resource));
  }

  private cached(key: string, loader: () => Promise<Uint8Array>): Promise<Uint8Array> {
    const existing = this.entries.get(key);
    if (existing !== undefined) return this.touch(key, existing);
    return this.load(key, loader);
  }

  private touch(key: string, content: Promise<Uint8Array>): Promise<Uint8Array> {
    this.entries.delete(key);
    this.entries.set(key, content);
    return content;
  }

  private load(key: string, loader: () => Promise<Uint8Array>): Promise<Uint8Array> {
    const content = loader().catch((error: unknown) => {
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
