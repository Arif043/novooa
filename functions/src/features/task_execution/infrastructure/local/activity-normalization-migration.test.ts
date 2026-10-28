import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test, {type TestContext} from "node:test";
import {connectRuntimeDatabase, type RuntimeDatabase} from "../../../../db/database.js";
import {activities} from "../../../../db/schema.js";

const originalActivity = {id: "activity-1", run_id: "run-1", node_id: "node-1", target: "node", primitive: "script",
  title: "Historischer Titel", status: "failed", input: "Eingabe", output: "Ausgabe",
  outputs_json: '{"custom":{"value":42}}', message: "Fehler", duration_ms: 123,
  created_at: "2026-01-01 10:00:00.123", console_json: '{"stdout":"ausgabe","stderr":"warnung"}'};

async function previousDatabase(t: TestContext) {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`PRAGMA foreign_keys = ON`);
  await database.run(sql`CREATE TABLE task_runs (id TEXT PRIMARY KEY, team_id TEXT NOT NULL, task_id TEXT NOT NULL)`);
  await database.run(sql`INSERT INTO task_runs VALUES ('run-1', 'team-1', 'task-1')`);
  await database.run(sql`CREATE TABLE activities (id TEXT PRIMARY KEY, team_id TEXT NOT NULL,
    run_id TEXT NOT NULL, task_id TEXT NOT NULL, node_id TEXT, target TEXT NOT NULL, primitive TEXT,
    title TEXT NOT NULL, status TEXT NOT NULL, input TEXT NOT NULL, output TEXT NOT NULL,
    outputs_json TEXT NOT NULL, message TEXT NOT NULL, duration_ms INTEGER, created_at TEXT NOT NULL, console_json TEXT NOT NULL)`);
  await database.run(sql`INSERT INTO activities VALUES (${originalActivity.id}, ${"team-1"},
    ${originalActivity.run_id}, ${"task-1"}, ${originalActivity.node_id}, ${originalActivity.target},
    ${originalActivity.primitive}, ${originalActivity.title}, ${originalActivity.status}, ${originalActivity.input},
    ${originalActivity.output}, ${originalActivity.outputs_json}, ${originalActivity.message}, ${originalActivity.duration_ms},
    ${originalActivity.created_at}, ${originalActivity.console_json})`);
  return database;
}

async function migrateActivities(database: RuntimeDatabase) {
  await runMigration(database, "0014_normalize_activities.sql");
}

async function runMigration(database: RuntimeDatabase, fileName: string) {
  const migration = await readFile(resolve(__dirname, "../../../../../drizzle", fileName), "utf8");
  await database.transaction(async (tx) => {
    for (const statement of migration.split("--> statement-breakpoint")) await tx.run(sql.raw(statement.trim()));
  });
}

test("migration preserves complete activity history and establishes run deletion cascade", async (t) => {
  const database = await previousDatabase(t);
  await migrateActivities(database);
  // Spätere Spalten, damit das aktuelle Schema die Zeile lesen kann.
  await runMigration(database, "0022_activity_failure_code.sql");
  await runMigration(database, "0023_activity_failure_details.sql");
  await runMigration(database, "0024_activity_conversation.sql");
  await runMigration(database, "0030_run_effects_and_graph_snapshot.sql");
  await runMigration(database, "0031_nested_activities.sql");
  assert.deepEqual(await database.select().from(activities), [{
    ...originalActivity, failure_code: null, failure_details_json: null, conversation_json: "[]", effects_json: "[]",
    parent_node_id: null, iteration: null, selected_branch_id: null,
  }]);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
  await database.run(sql`DELETE FROM task_runs WHERE id = 'run-1'`);
  assert.deepEqual(await database.select().from(activities), []);
});

for (const invalidColumn of ["team_id", "task_id", "run_id"]) {
  test(`migration rejects inconsistent ${invalidColumn} and rolls back all schema changes`, async (t) => {
    const database = await previousDatabase(t);
    await database.run(sql.raw(`UPDATE activities SET ${invalidColumn} = 'invalid'`));
    const originalRows = await database.all(sql`SELECT * FROM activities`);
    await assert.rejects(migrateActivities(database));
    assert.deepEqual(await database.all(sql`SELECT * FROM activities`), originalRows);
    assert.deepEqual(await database.all(sql`SELECT name FROM sqlite_master WHERE name = '__activity_run_guard'`), []);
  });
}
