import assert from "node:assert/strict";
import test from "node:test";
import {writeFileNodeExecutor} from "./write-file-node-executor.js";

test("writes a media reference as binary data with its image metadata", async () => {
  const writtenFiles: Array<Record<string, unknown>> = [];

  await writeFileNodeExecutor.execute(
    writeFileNode() as never,
    runContextFor(writtenFiles) as never,
  );

  const input = writtenFiles[0];
  assert.equal(input.contentType, "image/png");
  assert.equal(input.fileName, "entwurf.png");
  assert.deepEqual(
    Array.from(input.content as Uint8Array),
    [137, 80, 78, 71, 13, 10, 26, 10],
  );
});

test("writes a table value as an .xlsx file with a matching content type", async () => {
  const writtenFiles: Array<Record<string, unknown>> = [];

  await writeFileNodeExecutor.execute(
    writeFileNode() as never,
    runContextFor(writtenFiles, tableValue()) as never,
  );

  const input = writtenFiles[0];
  assert.equal(
    input.contentType,
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  );
  assert.equal(input.fileName, "entwurf.xlsx");
  assert.ok((input.content as Uint8Array).byteLength > 0);
});

function tableValue() {
  return {columns: ["name", "status"], rows: [["Lea", "aktiv"], ["Tom", null]]};
}

function writeFileNode() {
  return {
    id: "write",
    primitive: "writeFile",
    config: {
      primitive: "writeFile",
      contentTemplate: "{{bild.value}}",
      fileName: "entwurf.txt",
      contentType: "text/plain",
    },
  };
}

function mediaReference() {
  return {
    fileId: "image-1",
    versionId: "version-1",
    displayName: "eingabe.png",
    contentType: "image/png",
    sizeBytes: 8,
  };
}

function runContextFor(
  writtenFiles: Array<Record<string, unknown>>,
  resolvedValue: unknown = mediaReference(),
) {
  return {
    teamId: "team-1",
    templateExpressionResolver: {
      resolveText: (value: string) => value,
      resolveValue: () => resolvedValue,
    },
    fileContentReader: {
      async readTeamFileContent() {
        return {
          content: Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
          displayName: "eingabe.png",
          contentType: "image/png",
          sizeBytes: 8,
        };
      },
    },
    teamFileStore: {
      async writeTeamFile(input: Record<string, unknown>) {
        writtenFiles.push(input);
        return {
          fileId: "file-1",
          versionId: "version-1",
          storagePath: "teams/team-1/files/file-1/versions/version-1/entwurf.png",
          displayName: String(input.fileName),
          contentType: String(input.contentType),
          sizeBytes: (input.content as Uint8Array).byteLength,
          folderId: null,
          ownerUid: "system",
          isNewFile: true,
        };
      },
    },
  };
}
