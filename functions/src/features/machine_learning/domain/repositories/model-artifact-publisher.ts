import {type ModelArtifactReference, type ModelArtifactResourceReference} from "../entities/model-artifact-reference.js";

export type ModelArtifactPublication = {
  reference: ModelArtifactReference;
  content: AsyncIterable<Uint8Array>;
  resources?: readonly {reference: ModelArtifactResourceReference; content: AsyncIterable<Uint8Array>}[];
};

export interface ModelArtifactPublisher {
  publish(publication: ModelArtifactPublication): Promise<void>;
}
