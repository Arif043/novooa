export type MediaInputDefinition = {
  instruction: string;
};

export type MediaInputFileReference = {
  fileId: string;
  versionId: string;
  storagePath: string;
  displayName: string;
  contentType: string;
  sizeBytes: number;
};

export function validateMediaInputDefinition(
  definition: MediaInputDefinition,
): void {
  if (definition.instruction.trim().length === 0) {
    throw new Error("Die Medienaufnahme benötigt eine Anweisung.");
  }
}
