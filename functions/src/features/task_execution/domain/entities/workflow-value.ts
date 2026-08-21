export type FileReference = {
  fileId: string;
  versionId: string;
  displayName: string;
  contentType: string;
  sizeBytes: number;
};

export type MediaReference = FileReference;

export type NodeOutputValue =
  | {type: "string"; value: string}
  | {type: "datetime"; value: string}
  | {type: "number"; value: number}
  | {type: "boolean"; value: boolean}
  | {type: "json"; value: unknown}
  | {type: "file"; value: FileReference}
  | {type: "media"; value: MediaReference};

export function mediaReferenceFor(file: FileReference): MediaReference {
  if (!file.contentType.startsWith("image/")) {
    throw new Error("Die Medienreferenz muss auf ein Bild verweisen.");
  }
  return file;
}
