export type FileReference = {
  fileId: string;
  versionId: string;
  displayName: string;
  contentType: string;
  sizeBytes: number;
};

export type MediaReference = FileReference;

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
  | {type: "table"; value: WorkflowTable};

export function mediaReferenceFor(file: FileReference): MediaReference {
  if (!file.contentType.startsWith("image/")) {
    throw new Error("Die Medienreferenz muss auf ein Bild verweisen.");
  }
  return file;
}

export function tableOutput(value: WorkflowTable): NodeOutputValue {
  return {type: "table", value};
}
