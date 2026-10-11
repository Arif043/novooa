import {
  type ModelArtifactFileReference,
  type ModelArtifactReference,
  type ModelArtifactResourceReference,
} from "../entities/model-artifact-reference.js";

export type PublishedFile<Reference> = {reference: Reference; content: AsyncIterable<Uint8Array>};

export type ModelArtifactPublication = {
  reference: ModelArtifactReference;
  content: AsyncIterable<Uint8Array>;
  resources?: readonly PublishedFile<ModelArtifactResourceReference>[];
  externalData?: readonly PublishedFile<ModelArtifactFileReference>[];
};

export interface ModelArtifactPublisher {
  publish(publication: ModelArtifactPublication): Promise<void>;
}
