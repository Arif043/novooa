import {type ObjectStore} from "../../domain/repositories/object-store.js";
import {getDefaultStorageBucket} from "./firebase-storage.js";

export class FirebaseObjectStore implements ObjectStore {
  async downloadToFile(
    storagePath: string,
    destinationPath: string,
  ): Promise<void> {
    await getDefaultStorageBucket().file(storagePath).download({
      destination: destinationPath,
    });
  }
}
