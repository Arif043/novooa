import assert from "node:assert/strict";
import test from "node:test";
import {writeFileNodeExecutor} from "./write-file-node-executor.js";

test("writes an image data URL as binary data with its image metadata", async () => {
  const writtenFiles: Array<Record<string, unknown>> = [];
  const imageDataUrl = "data:image/png;base64,iVBORw0KGgo=";

  await writeFileNodeExecutor.execute({
    node: writeFileNode(),
  } as never, runContextFor(imageDataUrl, writtenFiles) as never);

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

function runContextFor(dataUrl: string, writtenFiles: Array<Record<string, unknown>>) {
  return {
    teamId: "team-1",
    task: {edges: [{from: "image", to: "write"}]},
    results: new Map([[
      "image",
      {outputs: {dataUrl: {type: "string", value: dataUrl}}},
    ]]),
    resolveTemplates: (value: string) => value,
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
