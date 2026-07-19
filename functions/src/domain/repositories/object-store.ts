export interface ObjectStore {
  downloadToFile(storagePath: string, destinationPath: string): Promise<void>;
}
