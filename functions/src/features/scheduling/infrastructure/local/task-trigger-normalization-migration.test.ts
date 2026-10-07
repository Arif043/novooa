import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test, {type TestContext} from "node:test";
import {connectRuntimeDatabase, type RuntimeDatabase} from "../../../../db/database.js";
import {taskTriggers} from "../../../../db/schema.js";

const originalTrigger = {id: "trigger-1", task_id: "task-1", type: "schedule", enabled: 0,
  config_json: '{"kind":"weekly","custom":{"value":42}}', event_config_json: '{"custom":"erhalten"}',
  policy_json: '{"ifRunning":"startParallel"}', next_run_at: "2026-02-01", last_run_at: "2026-01-01",
  last_run_id: "historical-run", created_by_uid: "user-1", created_at: "2025-01-01", updated_at: "2026-01-02"};

async function previousDatabase(t: TestContext) {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`PRAGMA foreign_keys = ON`);
  await database.run(sql`CREATE TABLE tasks (id TEXT PRIMARY KEY, team_id TEXT NOT NULL)`);
  await database.run(sql`INSERT INTO tasks VALUES ('task-1', 'team-1')`);
  await database.run(sql`CREATE TABLE task_triggers (id TEXT PRIMARY KEY, team_id TEXT NOT NULL,
    task_id TEXT NOT NULL, type TEXT NOT NULL, enabled INTEGER NOT NULL, config_json TEXT NOT NULL,
    event_config_json TEXT NOT NULL, policy_json TEXT NOT NULL, next_run_at TEXT, last_run_at TEXT,
    last_run_id TEXT, created_by_uid TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)`);
  await database.run(sql`INSERT INTO task_triggers VALUES (${originalTrigger.id}, ${"team-1"},
    ${originalTrigger.task_id}, ${originalTrigger.type}, ${originalTrigger.enabled}, ${originalTrigger.config_json},
    ${originalTrigger.event_config_json}, ${originalTrigger.policy_json}, ${originalTrigger.next_run_at},
    ${originalTrigger.last_run_at}, ${originalTrigger.last_run_id}, ${originalTrigger.created_by_uid},
    ${originalTrigger.created_at}, ${originalTrigger.updated_at})`);
  return database;
}

async function migrateTriggers(database: RuntimeDatabase) {
  const migration = await readFile(resolve(__dirname, "../../../../../drizzle/0013_normalize_task_triggers.sql"), "utf8");
  await database.transaction(async (tx) => {
    for (const statement of migration.split("--> statement-breakpoint")) await tx.run(sql.raw(statement.trim()));
  });
}

test("migration preserves trigger JSON, scheduling state, historical references and timestamps", async (t) => {
  const database = await previousDatabase(t);
  await migrateTriggers(database);
  assert.deepEqual(await database.select().from(taskTriggers), [originalTrigger]);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
  await database.run(sql`DELETE FROM tasks WHERE id = 'task-1'`);
  assert.deepEqual(await database.select().from(taskTriggers), []);
});

for (const invalidReference of ["foreign-team", "missing-task"]) {
  test(`migration rejects ${invalidReference} without changing existing trigger data`, async (t) => {
    const database = await previousDatabase(t);
    if (invalidReference === "foreign-team") await database.run(sql`UPDATE task_triggers SET team_id = 'team-2'`);
    else await database.run(sql`UPDATE task_triggers SET task_id = 'missing'`);
    const originalRows = await database.all(sql`SELECT * FROM task_triggers`);
    await assert.rejects(migrateTriggers(database));
    assert.deepEqual(await database.all(sql`SELECT * FROM task_triggers`), originalRows);
    assert.deepEqual(await database.all(sql`SELECT name FROM sqlite_master WHERE name = '__task_trigger_team_guard'`), []);
  });
}
