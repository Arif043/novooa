export type ModelArtifactReference = {
  artifactId: string;
  versionId: string;
  format: "onnx";
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
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
