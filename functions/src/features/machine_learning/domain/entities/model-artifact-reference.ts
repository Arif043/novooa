export type ModelArtifactReference = {
  artifactId: string;
  versionId: string;
  format: "onnx";
  contentType: string;
  sizeBytes: number;
  sha256: string;
  resources?: readonly ModelArtifactResourceReference[];
};

export type ModelArtifactResourceReference = {
  name: string;
  contentType: string;
  sizeBytes: number;
  sha256: string;
};

export function validateModelArtifactReference(
  reference: ModelArtifactReference,
): void {
  required(reference.artifactId, "Die Modell-Artefakt-ID fehlt.");
  required(reference.versionId, "Die Modell-Artefakt-Version fehlt.");
  required(reference.contentType, "Der Content-Type des Modell-Artefakts fehlt.");
  if (!Number.isSafeInteger(reference.sizeBytes) || reference.sizeBytes <= 0) {
    throw new Error("Die Größe des Modell-Artefakts ist ungültig.");
  }
  if (!/^[a-f0-9]{64}$/i.test(reference.sha256)) {
    throw new Error("Die SHA-256-Prüfsumme des Modell-Artefakts ist ungültig.");
  }
  validateResources(reference.resources ?? []);
}

function validateResources(resources: readonly ModelArtifactResourceReference[]): void {
  const names = new Set<string>();
  for (const resource of resources) {
    required(resource.name, "Der Name einer Modellressource fehlt.");
    required(resource.contentType, "Der Content-Type einer Modellressource fehlt.");
    if (!Number.isSafeInteger(resource.sizeBytes) || resource.sizeBytes <= 0) throw new Error("Die Größe einer Modellressource ist ungültig.");
    if (!/^[a-f0-9]{64}$/i.test(resource.sha256)) throw new Error("Die SHA-256-Prüfsumme einer Modellressource ist ungültig.");
    if (names.has(resource.name)) throw new Error("Die Namen der Modellressourcen müssen eindeutig sein.");
    names.add(resource.name);
  }
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
