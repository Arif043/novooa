import {getStorage} from "firebase-admin/storage";
import {type ObjectStore} from "../../domain/repositories/object-store.js";

export class FirebaseObjectStore implements ObjectStore {
  async downloadToFile(
    storagePath: string,
    destinationPath: string,
  ): Promise<void> {
    await getStorage().bucket().file(storagePath).download({
      destination: destinationPath,
    });
  }
}
