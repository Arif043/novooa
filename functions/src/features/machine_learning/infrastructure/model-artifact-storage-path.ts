import {
  type ModelArtifactFileReference,
  type ModelArtifactReference,
  type ModelArtifactResourceReference,
} from "../domain/entities/model-artifact-reference.js";

/** Ordner einer Modellversion — lokal unter dem Runtime-Verzeichnis wie im globalen Modellspeicher. */
export function modelArtifactDirectoryFor(reference: ModelArtifactReference): string {
  return `model-artifacts/${pathSegment(reference.artifactId)}/versions/${pathSegment(reference.versionId)}`;
}

export function modelArtifactStoragePathFor(reference: ModelArtifactReference): string {
  return `${modelArtifactDirectoryFor(reference)}/model.onnx`;
}

export function modelArtifactResourceStoragePathFor(reference: ModelArtifactReference, resource: ModelArtifactResourceReference): string {
  return `${modelArtifactDirectoryFor(reference)}/resources/${pathSegment(resource.name)}`;
}

/** Gewichte liegen unter ihrem Namen direkt neben model.onnx, weil ONNX Runtime sie dort sucht. */
export function modelArtifactExternalDataStoragePathFor(reference: ModelArtifactReference, file: ModelArtifactFileReference): string {
  return `${modelArtifactDirectoryFor(reference)}/${pathSegment(file.name)}`;
}

function pathSegment(value: string): string {
  if (/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$/.test(value)) return value;
  throw new Error("Die Modell-Artefakt-Referenz enthält einen ungültigen Pfadbestandteil.");
}
