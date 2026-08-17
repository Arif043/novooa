export type MediaInputSource = "gallery" | "camera";

export type MediaInputDefinition = {
  instruction: string;
  source: MediaInputSource;
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
  if (definition.source === "gallery" || definition.source === "camera") return;
  throw new Error("Die Quelle der Medienaufnahme ist ungültig.");
}
