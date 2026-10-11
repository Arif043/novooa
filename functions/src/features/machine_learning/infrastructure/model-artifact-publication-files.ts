import {type ModelArtifactPublication} from "../domain/repositories/model-artifact-publisher.js";
import {
  modelArtifactExternalDataStoragePathFor,
  modelArtifactResourceStoragePathFor,
  modelArtifactStoragePathFor,
} from "./model-artifact-storage-path.js";

/** Eine zu speichernde Datei einer Modellversion mit ihrem Pfad im Modellspeicher. */
export type PublicationFile = {
  storagePath: string;
  contentType: string;
  sizeBytes: number;
  sha256: string;
  content: AsyncIterable<Uint8Array>;
};

export function publicationFiles(publication: ModelArtifactPublication): readonly PublicationFile[] {
  const {reference} = publication;
  return [
    {storagePath: modelArtifactStoragePathFor(reference), ...fileOf(reference, reference.contentType), content: publication.content},
    ...(publication.externalData ?? []).map((file) => ({
      storagePath: modelArtifactExternalDataStoragePathFor(reference, file.reference),
      ...fileOf(file.reference, "application/octet-stream"), content: file.content,
    })),
    ...(publication.resources ?? []).map((file) => ({
      storagePath: modelArtifactResourceStoragePathFor(reference, file.reference),
      ...fileOf(file.reference, file.reference.contentType), content: file.content,
    })),
  ];
}

function fileOf(reference: {sizeBytes: number; sha256: string}, contentType: string) {
  return {contentType, sizeBytes: reference.sizeBytes, sha256: reference.sha256};
}
