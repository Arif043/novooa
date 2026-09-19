import assert from "node:assert/strict";
import test from "node:test";
import {writeFileNodeExecutor} from "./write-file-node-executor.js";

test("writes a media reference as binary data with its image metadata", async () => {
  const writtenFiles: Array<Record<string, unknown>> = [];

  await writeFileNodeExecutor.execute(
    writeFileNode() as never,
    runContextFor(writtenFiles) as never,
    [mediaOutput()] as never,
  );

  const input = writtenFiles[0];
  assert.equal(input.contentType, "image/png");
  assert.equal(input.fileName, "entwurf.png");
  assert.deepEqual(
    Array.from(input.content as Uint8Array),
    [137, 80, 78, 71, 13, 10, 26, 10],
  );
});

function writeFileNode() {
  return {
    id: "write",
    primitive: "writeFile",
    config: {
      primitive: "writeFile",
      fileName: "entwurf.txt",
      contentType: "text/plain",
    },
  };
}

function mediaOutput() {
  return {
    nodeId: "image",
    outputName: "value",
    value: {
      type: "media",
      value: {
        fileId: "image-1",
        versionId: "version-1",
        displayName: "eingabe.png",
        contentType: "image/png",
        sizeBytes: 8,
      },
    },
  };
}

function runContextFor(writtenFiles: Array<Record<string, unknown>>) {
  return {
    teamId: "team-1",
    resolveTemplates: (value: string) => value,
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
