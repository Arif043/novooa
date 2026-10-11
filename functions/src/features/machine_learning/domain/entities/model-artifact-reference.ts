export type ModelArtifactReference = {
  artifactId: string;
  versionId: string;
  format: "onnx";
  contentType: string;
  sizeBytes: number;
  sha256: string;
  resources?: readonly ModelArtifactResourceReference[];
  /** Ausgelagerte Gewichte (ONNX External Data); sie liegen unter ihrem Namen neben dem Modell. */
  externalData?: readonly ModelArtifactFileReference[];
};

export type ModelArtifactFileReference = {
  name: string;
  sizeBytes: number;
  sha256: string;
};

export type ModelArtifactResourceReference = ModelArtifactFileReference & {
  contentType: string;
};

const fileNamePattern = /^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/;
/** Namen, die im Ordner eines Modells bereits belegt sind. */
const reservedNames = new Set(["model.onnx", "resources"]);

export function validateModelArtifactReference(
  reference: ModelArtifactReference,
): void {
  required(reference.artifactId, "Die Modell-Artefakt-ID fehlt.");
  required(reference.versionId, "Die Modell-Artefakt-Version fehlt.");
  required(reference.contentType, "Der Content-Type des Modell-Artefakts fehlt.");
  validSize(reference.sizeBytes, "Die Größe des Modell-Artefakts ist ungültig.");
  validChecksum(reference.sha256, "Die SHA-256-Prüfsumme des Modell-Artefakts ist ungültig.");
  validateFiles(reference.resources ?? [], {one: "Modellressource", many: "Modellressourcen"});
  for (const resource of reference.resources ?? []) required(resource.contentType, "Der Content-Type einer Modellressource fehlt.");
  validateFiles(reference.externalData ?? [], {one: "Gewichtsdatei", many: "Gewichtsdateien"});
  for (const file of reference.externalData ?? []) {
    if (reservedNames.has(file.name)) throw new Error(`Der Name der Gewichtsdatei „${file.name}“ ist reserviert.`);
  }
}

function validateFiles(files: readonly ModelArtifactFileReference[], kind: {one: string; many: string}): void {
  const names = new Set<string>();
  for (const file of files) {
    if (!fileNamePattern.test(file.name)) throw new Error(`Der Name einer ${kind.one} ist ungültig.`);
    validSize(file.sizeBytes, `Die Größe einer ${kind.one} ist ungültig.`);
    validChecksum(file.sha256, `Die SHA-256-Prüfsumme einer ${kind.one} ist ungültig.`);
    if (names.has(file.name)) throw new Error(`Die Namen der ${kind.many} müssen eindeutig sein.`);
    names.add(file.name);
  }
}

function validSize(value: number, message: string): void {
  if (!Number.isSafeInteger(value) || value <= 0) throw new Error(message);
}

function validChecksum(value: string, message: string): void {
  if (!/^[a-f0-9]{64}$/i.test(value)) throw new Error(message);
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
