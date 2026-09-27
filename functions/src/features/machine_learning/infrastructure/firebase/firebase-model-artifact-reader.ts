import {getDefaultStorageBucket} from "../../../files/infrastructure/firebase/firebase-storage.js";
import {type ModelArtifactReference, type ModelArtifactResourceReference} from "../../domain/entities/model-artifact-reference.js";
import {type ModelArtifactReader} from "../../domain/repositories/model-artifact-reader.js";
import {verifyModelArtifact} from "../model-artifact-integrity.js";
import {modelArtifactResourceStoragePathFor, modelArtifactStoragePathFor} from "../model-artifact-storage-path.js";

export class FirebaseModelArtifactReader implements ModelArtifactReader {
  async read(reference: ModelArtifactReference): Promise<Uint8Array> {
    const [content] = await getDefaultStorageBucket()
      .file(modelArtifactStoragePathFor(reference))
      .download();
    return verifyModelArtifact(reference, content);
  }

  async readResource(reference: ModelArtifactReference, resource: ModelArtifactResourceReference): Promise<Uint8Array> {
    const [content] = await getDefaultStorageBucket().file(modelArtifactResourceStoragePathFor(reference, resource)).download();
    return verifyModelArtifact({...reference, ...resource}, content);
  }
}
