import {getDefaultStorageBucket} from "../../../files/infrastructure/firebase/firebase-storage.js";
import {type ModelArtifactReference} from "../../domain/entities/model-artifact-reference.js";
import {type ModelArtifactReader} from "../../domain/repositories/model-artifact-reader.js";
import {verifyModelArtifact} from "../model-artifact-integrity.js";
import {modelArtifactStoragePathFor} from "../model-artifact-storage-path.js";

export class FirebaseModelArtifactReader implements ModelArtifactReader {
  async read(reference: ModelArtifactReference): Promise<Uint8Array> {
    const [content] = await getDefaultStorageBucket()
      .file(modelArtifactStoragePathFor(reference))
      .download();
    return verifyModelArtifact(reference, content);
  }
}
