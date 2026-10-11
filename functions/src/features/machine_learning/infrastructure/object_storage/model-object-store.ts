/** Ein Objektspeicher für Modelldateien; die Prüfsumme steht in den Metadaten jedes Objekts. */
export interface ModelObjectStore {
  storedSha256(key: string): Promise<string | null>;
  put(key: string, content: AsyncIterable<Uint8Array>, metadata: ModelObjectMetadata): Promise<void>;
}

export type ModelObjectMetadata = {
  contentType: string;
  sizeBytes: number;
  sha256: string;
};
