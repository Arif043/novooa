export interface TransferArchiveWriter {
  addJson(name: string, value: unknown): Promise<void>;
  addBlob(name: string, content: AsyncIterable<Uint8Array>): Promise<void>;
}

export interface TransferArchiveReader {
  /** `undefined`, wenn der Eintrag im Archiv fehlt. */
  json(name: string): Promise<unknown>;
  /** Ruft `consumer` nacheinander für jeden gefundenen Eintrag aus `names` auf. */
  forEachBlob(
    names: ReadonlySet<string>,
    consumer: (name: string, content: Uint8Array) => Promise<void>,
  ): Promise<void>;
}

export function transferBlobEntry(storagePath: string): string {
  return `blobs/${storagePath}`;
}

export function transferDataEntry(name: string): string {
  return `data/${name}.json`;
}
