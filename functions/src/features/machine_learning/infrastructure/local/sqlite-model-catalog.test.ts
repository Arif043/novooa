import assert from "node:assert/strict";
import test from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {modelCatalog, type NewModelCatalog} from "../../../../db/schema.js";
import {SQLiteModelCatalog} from "./sqlite-model-catalog.js";

test("lists only system and active-team models", async (t) => {
  const database = await runtimeTestDatabase(t);
  await database.insert(modelCatalog).values([modelRow("system", null), modelRow("team", "team-1")]);
  const catalog = new SQLiteModelCatalog(database);
  assert.deepEqual((await catalog.listAvailableFor("team-1")).map(entry => entry.scope.type), ["system", "team"]);
  assert.deepEqual((await catalog.listAvailableFor("other-team")).map(entry => entry.scope.type), ["system"]);
});

test("writes logical artifacts instead of physical storage paths", async (t) => {
  const database = await runtimeTestDatabase(t);
  await new SQLiteModelCatalog(database).save(modelEntry());
  const row = await database.select().from(modelCatalog).get();
  assert.ok(row?.artifact_reference_json.includes("artifact-1"));
  assert.equal(row?.artifact_reference_json.includes("storagePath"), false);
});

function modelRow(scope: "system" | "team", teamId: string | null): NewModelCatalog {
  return {
    id: `${scope}-model`,
    title: `${scope} model`,
    description: "Ein Testmodell.",
    tags_json: "[\"bild\"]",
    scope,
    team_id: teamId,
    runtime: "onnx",
    artifact_reference_json: JSON.stringify(artifact()),
    contract_json: JSON.stringify(contract()),
  };
}

function modelEntry() {
  return {
    id: "system-model",
    title: "Systemmodell",
    description: "Ein Testmodell.",
    tags: ["bild"],
    scope: {type: "system" as const},
    runtime: "onnx" as const,
    artifactReference: artifact(),
    contract: contract(),
  };
}

function artifact() {
  return {
    artifactId: "artifact-1",
    versionId: "version-1",
    format: "onnx" as const,
    contentType: "application/onnx",
    sizeBytes: 128,
    sha256: "b".repeat(64),
  };
}

function contract() {
  return {
    inputs: [{
      name: "input",
      source: "image" as const,
      dataType: "float32" as const,
      shape: ["dynamic" as const, 3, 16, 16],
      transformations: [],
    }],
    outputs: [{
      name: "output",
      dataType: "float32" as const,
      shape: ["dynamic" as const, 2],
      semantic: "classification.scores",
      transformations: [], workflowOutput: {name: "value", type: "json" as const, mapping: "$tensor"},
    }],
  };
}
