import assert from "node:assert/strict";
import test from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {modelCatalog, type NewModelCatalog} from "../../../../db/schema.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {sql} from "drizzle-orm";
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

test("derives scope and ONNX runtime without duplicate storage columns", async (t) => {
  const database = await runtimeTestDatabase(t);
  const catalog = new SQLiteModelCatalog(database);
  await catalog.save({...modelEntry(), scope: {type: "team", teamId: "team-1"}});
  const entry = await catalog.findAvailableFor("team-1", "system-model");
  assert.deepEqual(entry?.scope, {type: "team", teamId: "team-1"});
  assert.equal(entry?.runtime, "onnx");
  assert.equal(await catalog.findAvailableFor("another-team", "system-model"), null);
  const columns = await database.all<{name: string}>(sql`PRAGMA table_info(model_catalog)`);
  assert.ok(!columns.some((column) => ["scope", "runtime"].includes(column.name)));
});

test("team deletion APIs cannot remove system models or models of another team", async (t) => {
  const database = await runtimeTestDatabase(t);
  const catalog = new SQLiteModelCatalog(database);
  await catalog.save(modelEntry());
  await catalog.save({...modelEntry(), id: "team-model", scope: {type: "team", teamId: "team-1"}});
  assert.equal(await catalog.removeTeamEntry("team-1", "system-model"), false);
  assert.equal(await catalog.removeTeamEntry("another-team", "team-model"), false);
  assert.equal(await catalog.removeTeamEntry("team-1", "team-model"), true);
  assert.equal((await catalog.listAvailableFor("team-1")).length, 1);
});

for (const override of [{runtime: "unsupported"}, {scope: {type: "organization"}}]) {
  test(`rejects an invalid ${Object.keys(override)[0]} before modifying persisted entries`, async (t) => {
    const database = await runtimeTestDatabase(t);
    const catalog = new SQLiteModelCatalog(database);
    await catalog.save(modelEntry());
    const invalidEntry = {...modelEntry(), ...override, title: "Ungültig"} as unknown as ModelCatalogEntry;
    await assert.rejects(catalog.save(invalidEntry));
    assert.equal((await catalog.findAvailableFor("team-1", "system-model"))?.title, "Systemmodell");
  });
}

function modelRow(scope: "system" | "team", teamId: string | null): NewModelCatalog {
  return {
    id: `${scope}-model`,
    title: `${scope} model`,
    description: "Ein Testmodell.",
    tags_json: "[\"bild\"]",
    team_id: teamId,
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
