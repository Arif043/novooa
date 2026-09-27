import {type ModelArtifactReference, type ModelArtifactResourceReference} from "../entities/model-artifact-reference.js";

export interface ModelArtifactReader {
  read(reference: ModelArtifactReference): Promise<Uint8Array>;
  readResource?(reference: ModelArtifactReference, resource: ModelArtifactResourceReference): Promise<Uint8Array>;
}
