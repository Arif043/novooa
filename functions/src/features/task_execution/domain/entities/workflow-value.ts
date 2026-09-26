export type FileReference = {
  fileId: string;
  versionId: string;
  displayName: string;
  contentType: string;
  sizeBytes: number;
};

export type MediaReference = FileReference;
export type AudioReference = FileReference;

/** Ein fachlicher Tabellen-Wert: Spaltennamen plus Zeilen, jede Zeile auf
 * `columns` ausgerichtet (fehlende Felder als `null`). Schemalos, da
 * Datensammlungen selbst schemalos sind. */
export type WorkflowTable = {
  columns: string[];
  rows: unknown[][];
};

export type NodeOutputValue =
  | {type: "string"; value: string}
  | {type: "datetime"; value: string}
  | {type: "number"; value: number}
  | {type: "boolean"; value: boolean}
  | {type: "json"; value: unknown}
  | {type: "file"; value: FileReference}
  | {type: "media"; value: MediaReference}
  | {type: "audio"; value: AudioReference}
  | {type: "table"; value: WorkflowTable};

export function mediaReferenceFor(file: FileReference): MediaReference {
  if (!file.contentType.startsWith("image/")) {
    throw new Error("Die Medienreferenz muss auf ein Bild verweisen.");
  }
  return file;
}

export function audioReferenceFor(file: FileReference): AudioReference {
  if (!file.contentType.startsWith("audio/")) {
    throw new Error("Die Audioreferenz muss auf eine Audiodatei verweisen.");
  }
  return file;
}

export function tableOutput(value: WorkflowTable): NodeOutputValue {
  return {type: "table", value};
}

/** Übersetzt einen rohen Primitiv-Wert (z.B. aus einem typisierten
 * Formular- oder strukturierten Prompt-Feld) in seinen passenden,
 * getaggten `NodeOutputValue` — einzige Stelle für dieses Mapping, damit
 * `string`/`number`/`boolean` überall gleich getaggt werden. */
export function primitiveNodeOutputValue(
  value: string | number | boolean,
): NodeOutputValue {
  if (typeof value === "number") return {type: "number", value};
  if (typeof value === "boolean") return {type: "boolean", value};
  return {type: "string", value};
}
