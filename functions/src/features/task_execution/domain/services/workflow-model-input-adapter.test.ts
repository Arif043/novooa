import assert from "node:assert/strict";
import test from "node:test";
import {modelInputForWorkflowValue} from "./workflow-model-input-adapter.js";

test("adapts every workflow value into a model input", async () => {
  const values = await Promise.all([
    inputFor({type: "string", value: "Text"}),
    inputFor({type: "datetime", value: "2026-08-22T10:00:00.000Z"}),
    inputFor({type: "number", value: 3}),
    inputFor({type: "boolean", value: true}),
    inputFor({type: "json", value: {priority: "high"}}),
    inputFor(fileValue("application/pdf")),
    inputFor(fileValue("image/png")),
  ]);

  assert.deepEqual(values.map((value) => value.type), [
    "text", "datetime", "number", "boolean", "json", "file", "image",
  ]);
});

function inputFor(value: Parameters<typeof modelInputForWorkflowValue>[0]) {
  return modelInputForWorkflowValue(value, "team", {
    async readTeamFileContent(_teamId, fileId, _versionId) {
      const contentType = fileId === "image" ? "image/png" : "application/pdf";
      return {
        content: Uint8Array.from([1]), displayName: "datei", contentType, sizeBytes: 1,
      };
    },
  });
}

function fileValue(contentType: string): Parameters<typeof modelInputForWorkflowValue>[0] {
  return {
    type: "file",
    value: {
      fileId: contentType.startsWith("image/") ? "image" : "document",
      versionId: "version",
      displayName: "datei",
      contentType,
      sizeBytes: 1,
    },
  };
}
