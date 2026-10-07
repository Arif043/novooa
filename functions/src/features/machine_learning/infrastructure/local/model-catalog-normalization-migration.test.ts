import {getTableColumns, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test, {type TestContext} from "node:test";
import {connectRuntimeDatabase, type RuntimeDatabase} from "../../../../db/database.js";
import {modelCatalog} from "../../../../db/schema.js";

const originalModel = {id: "model-1", title: "Modell", description: "Beschreibung",
  translations_json: '{"de":{"title":"Titel","description":"Text"}}', tags_json: '["tag"]',
  team_id: "team-1", artifact_reference_json: '{"artifactId":"artifact-1","resources":[]}',
  contract_json: '{"inputs":[],"outputs":[]}', created_at: "2026-01-01", updated_at: "2026-01-02"};

async function previousDatabase(t: TestContext) {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`PRAGMA foreign_keys = ON`);
  await database.run(sql`CREATE TABLE teams (id TEXT PRIMARY KEY)`);
  await database.run(sql`INSERT INTO teams VALUES ('team-1')`);
  await database.run(sql`CREATE TABLE model_catalog (id TEXT PRIMARY KEY, title TEXT NOT NULL,
    description TEXT NOT NULL, translations_json TEXT NOT NULL, tags_json TEXT NOT NULL, scope TEXT NOT NULL,
    team_id TEXT REFERENCES teams(id) ON DELETE CASCADE, runtime TEXT NOT NULL,
    artifact_reference_json TEXT NOT NULL, contract_json TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)`);
  await database.run(sql`INSERT INTO model_catalog VALUES (${originalModel.id}, ${originalModel.title},
    ${originalModel.description}, ${originalModel.translations_json}, ${originalModel.tags_json}, ${"team"},
    ${originalModel.team_id}, ${"onnx"}, ${originalModel.artifact_reference_json}, ${originalModel.contract_json},
    ${originalModel.created_at}, ${originalModel.updated_at})`);
  return database;
}

async function migrateCatalog(database: RuntimeDatabase) {
  const migration = await readFile(resolve(__dirname, "../../../../../drizzle/0015_normalize_model_catalog.sql"), "utf8");
  await database.transaction(async (tx) => {
    for (const statement of migration.split("--> statement-breakpoint")) await tx.run(sql.raw(statement.trim()));
  });
}

test("migration preserves model payloads, ownership, timestamps and team cascade", async (t) => {
  const database = await previousDatabase(t);
  await database.run(sql`INSERT INTO model_catalog SELECT 'system-model', title, description,
    translations_json, tags_json, 'system', NULL, runtime, artifact_reference_json, contract_json, created_at, updated_at FROM model_catalog`);
  await migrateCatalog(database);
  // Nur die Spalten nach 0015; spätere Migrationen (z. B. `origin`) laufen hier nicht.
  const {origin: _origin, ...columnsAfter0015} = getTableColumns(modelCatalog);
  const rows = await database.select(columnsAfter0015).from(modelCatalog).orderBy(modelCatalog.id);
  assert.deepEqual(rows, [originalModel, {...originalModel, id: "system-model", team_id: null}]);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
  await database.run(sql`DELETE FROM teams WHERE id = 'team-1'`);
  assert.deepEqual((await database.select({id: modelCatalog.id}).from(modelCatalog)).map((row) => row.id), ["system-model"]);
});

for (const invalidValue of ["scope = 'system'", "team_id = NULL", "runtime = 'unsupported'"]) {
  test(`migration rejects ${invalidValue} and rolls back completely`, async (t) => {
    const database = await previousDatabase(t);
    await database.run(sql.raw(`UPDATE model_catalog SET ${invalidValue}`));
    const originalRows = await database.all(sql`SELECT * FROM model_catalog`);
    await assert.rejects(migrateCatalog(database));
    assert.deepEqual(await database.all(sql`SELECT * FROM model_catalog`), originalRows);
    assert.deepEqual(await database.all(sql`SELECT name FROM sqlite_master WHERE name = '__model_catalog_guard'`), []);
  });
}
