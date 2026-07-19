import {copyFile, mkdir} from "node:fs/promises";
import path from "node:path";
import {type ObjectStore} from "../../domain/repositories/object-store.js";

export class LocalObjectStore implements ObjectStore {
  constructor(private readonly rootDirectory: string) {}

  async downloadToFile(
    storagePath: string,
    destinationPath: string,
  ): Promise<void> {
    await mkdir(path.dirname(destinationPath), {recursive: true});
    await copyFile(path.join(this.rootDirectory, storagePath), destinationPath);
  }
}
