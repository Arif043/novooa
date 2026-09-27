import {type ModelArtifactReference, type ModelArtifactResourceReference} from "../domain/entities/model-artifact-reference.js";

export function modelArtifactStoragePathFor(
  reference: ModelArtifactReference,
): string {
  return `model-artifacts/${pathSegment(reference.artifactId)}/versions/${pathSegment(reference.versionId)}/model.onnx`;
}

export function modelArtifactResourceStoragePathFor(reference: ModelArtifactReference, resource: ModelArtifactResourceReference): string {
  return `model-artifacts/${pathSegment(reference.artifactId)}/versions/${pathSegment(reference.versionId)}/resources/${pathSegment(resource.name)}`;
}

function pathSegment(value: string): string {
  if (/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$/.test(value)) return value;
  throw new Error("Die Modell-Artefakt-Referenz enthält einen ungültigen Pfadbestandteil.");
}
