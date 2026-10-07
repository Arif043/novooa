import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test, {type TestContext} from "node:test";
import {connectRuntimeDatabase, type RuntimeDatabase} from "../../../../db/database.js";
import {taskRunJobs, taskRunSteps} from "../../../../db/schema.js";

const previousTables = [
  "CREATE TABLE teams (id TEXT PRIMARY KEY)",
  "CREATE TABLE task_runs (id TEXT PRIMARY KEY, team_id TEXT NOT NULL REFERENCES teams(id))",
  `CREATE TABLE task_run_jobs (id TEXT PRIMARY KEY, team_id TEXT NOT NULL REFERENCES teams(id),
    run_id TEXT NOT NULL REFERENCES task_runs(id) ON DELETE CASCADE, mode TEXT NOT NULL, status TEXT NOT NULL,
    attempts INTEGER NOT NULL, available_at TEXT NOT NULL, lease_expires_at TEXT,
    created_at TEXT NOT NULL, updated_at TEXT NOT NULL, UNIQUE(team_id, run_id))`,
  `CREATE TABLE task_run_steps (team_id TEXT NOT NULL REFERENCES teams(id),
    run_id TEXT NOT NULL REFERENCES task_runs(id) ON DELETE CASCADE, step_path TEXT NOT NULL,
    result_json TEXT NOT NULL, created_at TEXT NOT NULL, PRIMARY KEY(team_id, run_id, step_path))`,
  "INSERT INTO teams VALUES ('team-1'), ('team-2')",
  "INSERT INTO task_runs VALUES ('run-1', 'team-1')",
  `INSERT INTO task_run_jobs VALUES ('job-1', 'team-1', 'run-1', 'resume', 'leased', 2,
    '2026-01-01', '2026-01-03', '2026-01-01', '2026-01-02')`,
  `INSERT INTO task_run_steps VALUES ('team-1', 'run-1', 'branch/node-1', '{"output":"erhalten"}', '2026-01-02')`,
];

async function previousDatabase(t: TestContext) {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`PRAGMA foreign_keys = ON`);
  for (const statement of previousTables) await database.run(sql.raw(statement));
  return database;
}

async function migrateDependents(database: RuntimeDatabase) {
  const migration = await readFile(resolve(__dirname, "../../../../../drizzle/0012_normalize_run_dependents.sql"), "utf8");
  await database.transaction(async (tx) => {
    for (const statement of migration.split("--> statement-breakpoint")) await tx.run(sql.raw(statement.trim()));
  });
}

test("migration preserves queued work, lease state, step paths and JSON results", async (t) => {
  const database = await previousDatabase(t);
  await migrateDependents(database);
  assert.deepEqual(await database.select().from(taskRunJobs), [{id: "job-1", run_id: "run-1",
    mode: "resume", status: "leased", attempts: 2, available_at: "2026-01-01", lease_expires_at: "2026-01-03",
    created_at: "2026-01-01", updated_at: "2026-01-02"}]);
  assert.deepEqual(await database.select().from(taskRunSteps), [{run_id: "run-1", step_path: "branch/node-1",
    result_json: '{"output":"erhalten"}', created_at: "2026-01-02"}]);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
  await assert.rejects(database.run(sql`INSERT INTO task_run_jobs SELECT 'duplicate', run_id, mode,
    status, attempts, available_at, lease_expires_at, created_at, updated_at FROM task_run_jobs`));
  await assert.rejects(database.run(sql`INSERT INTO task_run_steps SELECT * FROM task_run_steps`));
});

for (const table of ["task_run_jobs", "task_run_steps"]) {
  test(`migration rejects a contradictory ${table} team without changing existing data`, async (t) => {
    const database = await previousDatabase(t);
    await database.run(sql.raw(`UPDATE ${table} SET team_id = 'team-2'`));
    const originalJobs = await database.all(sql`SELECT * FROM task_run_jobs`);
    const originalSteps = await database.all(sql`SELECT * FROM task_run_steps`);
    await assert.rejects(migrateDependents(database));
    assert.deepEqual(await database.all(sql`SELECT * FROM task_run_jobs`), originalJobs);
    assert.deepEqual(await database.all(sql`SELECT * FROM task_run_steps`), originalSteps);
    assert.deepEqual(await database.all(sql`SELECT name FROM sqlite_master WHERE name = '__run_dependents_team_guard'`), []);
  });
}
