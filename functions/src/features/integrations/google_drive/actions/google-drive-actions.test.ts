import assert from "node:assert/strict";
import test from "node:test";
import {type GoogleDriveActionContext} from "../domain/google-drive-action.js";
import {type GoogleDriveUpload} from "../domain/google-drive-file.js";
import {readAction} from "./read-action.js";
import {uploadAction} from "./upload-action.js";

function contextWith(params: Record<string, unknown>, values: Record<string, unknown> = {}) {
  const uploads: GoogleDriveUpload[] = [];
  const written: Array<{fileName: string; contentType: string}> = [];
  const context = {
    teamId: "team-1", params,
    resolveText: (template: string) => template.replace("{{name}}", "Bericht"),
    resolveValue: (template: string) => values[template] ?? template,
    drive: {
      upload: async (file: GoogleDriveUpload) => {
        uploads.push(file);
        return {id: "drive-1", name: file.name, mimeType: file.mimeType, webViewLink: "https://drive/drive-1", sizeBytes: 3};
      },
      download: async () => ({name: "rechnung.pdf", mimeType: "application/pdf", content: new Uint8Array([1])}),
    },
    files: {
      reader: {readTeamFileContent: async () => ({content: new Uint8Array([9]), contentType: "image/png"})},
      store: {writeTeamFile: async (input: {fileName: string; contentType: string}) => {
        written.push(input);
        return {fileId: "f1", versionId: "v1", displayName: input.fileName, contentType: input.contentType, sizeBytes: 1};
      }},
    },
  } as unknown as GoogleDriveActionContext;
  return {context, uploads, written};
}

test("Speichern legt Text mit aufgelöstem Namen im gewählten Ordner ab und liefert den Link", async () => {
  const {context, uploads} = contextWith({fileName: "{{name}}.txt", content: "Hallo", folderId: "ordner-1"});

  const outputs = await uploadAction.execute(context);

  assert.deepEqual(uploads[0], {name: "Bericht.txt", mimeType: "text/plain", content: "Hallo", folderId: "ordner-1"});
  assert.deepEqual(outputs.value, {type: "string", value: "https://drive/drive-1"});
  assert.deepEqual(outputs.driveFileId, {type: "string", value: "drive-1"});
});

test("ein Bild behält seinen Typ und bekommt die passende Endung", async () => {
  const {context, uploads} = contextWith({fileName: "Foto", content: "bild"}, {bild: {fileId: "f", versionId: "v"}});

  await uploadAction.execute(context);

  assert.equal(uploads[0].name, "Foto.png");
  assert.equal(uploads[0].mimeType, "image/png");
  assert.equal(uploads[0].folderId, undefined);
});

test("ohne Dateinamen wird nichts hochgeladen", async () => {
  const {context, uploads} = contextWith({fileName: " ", content: "x"});

  await assert.rejects(uploadAction.execute(context), /Dateinamen/);
  assert.equal(uploads.length, 0);
});

test("Lesen legt die Drive-Datei als Team-Datei ab", async () => {
  const {context, written} = contextWith({fileId: "datei-1"});

  const outputs = await readAction.execute(context);

  assert.deepEqual(written[0], {
    teamId: "team-1", content: new Uint8Array([1]), fileName: "rechnung.pdf", contentType: "application/pdf",
    folderId: null, targetFileId: null,
  });
  assert.equal(outputs.value.type, "file");
  assert.deepEqual(outputs.driveFileId, {type: "string", value: "datei-1"});
});
