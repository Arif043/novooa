import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test from "node:test";
import {connectRuntimeDatabase} from "../../../../db/database.js";
import {languageModels} from "../../../../db/schema.js";

const previousTables = [
  "CREATE TABLE language_model_connections (id TEXT PRIMARY KEY)",
  `CREATE TABLE language_models (id TEXT PRIMARY KEY, team_id TEXT NOT NULL, connection_id TEXT NOT NULL,
    name TEXT NOT NULL, model_id TEXT NOT NULL, capabilities_json TEXT NOT NULL,
    created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
    FOREIGN KEY (connection_id) REFERENCES language_model_connections(id) ON DELETE CASCADE)`,
  "INSERT INTO language_model_connections VALUES ('connection-1')",
  `INSERT INTO language_models VALUES ('model-1', 'team-1', 'connection-1', 'Modell', 'provider-model',
    '{"textGeneration":true}', '2026-01-01', '2026-01-02')`,
];

test("model normalization preserves profile metadata, JSON and references in a transaction", async (t) => {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`PRAGMA foreign_keys = ON`);
  for (const statement of previousTables) await database.run(sql.raw(statement));
  const migration = await readFile(resolve(__dirname, "../../../../../drizzle/0010_normalize_language_models.sql"), "utf8");
  await database.transaction(async (tx) => {
    for (const statement of migration.split("--> statement-breakpoint")) await tx.run(sql.raw(statement.trim()));
  });
  const [model] = await database.select().from(languageModels);
  assert.equal(model.connection_id, "connection-1");
  assert.equal(model.capabilities_json, '{"textGeneration":true}');
  assert.equal(model.model_id, "provider-model");
  assert.equal(model.created_at, "2026-01-01");
  assert.equal(model.updated_at, "2026-01-02");
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
});
