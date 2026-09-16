import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {LocalFileModelCatalog} from "./local-file-model-catalog.js";

test("persists model entries and filters team-scoped entries", async () => {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-model-catalog-"));
  const catalog = new LocalFileModelCatalog(directory);

  try {
    await catalog.save(systemEntry());
    await catalog.save({...systemEntry(), id: "team-model", scope: {type: "team", teamId: "team-2"}});

    assert.equal((await catalog.listAvailableFor("team-1")).length, 1);
    assert.equal((await catalog.findAvailableFor("team-1", "system-model"))?.id, "system-model");
    assert.equal(await catalog.findAvailableFor("team-1", "team-model"), null);
  } finally {
    await rm(directory, {recursive: true, force: true});
  }
});

function systemEntry(): ModelCatalogEntry {
  return {
    id: "system-model", title: "Systemmodell", description: "Testmodell", tags: ["test"],
    scope: {type: "system"}, runtime: "onnx",
    artifactReference: {
      artifactId: "system-model", versionId: "v1", format: "onnx",
      contentType: "application/onnx", sizeBytes: 1,
      sha256: "a".repeat(64),
    },
    contract: {
      inputs: [{name: "input", source: "tensor", dataType: "uint8", shape: [1], transformations: []}],
      outputs: [{name: "output", dataType: "uint8", shape: [1], semantic: "classification.scores", transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"}}],
    },
  };
}
