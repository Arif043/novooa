import {type ModelArtifactReference} from "../entities/model-artifact-reference.js";

export interface ModelArtifactReader {
  read(reference: ModelArtifactReference): Promise<Uint8Array>;
}
