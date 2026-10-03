import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {connectRuntimeDatabase} from "../../../../db/database.js";
import {activities} from "../../../../db/schema.js";
import {type NodeExecutionResult} from "../../domain/entities/task.js";
import {SQLiteActivityStore} from "./sqlite-activity-store.js";

const run = {runId: "run-1", taskId: "task-1", taskTitle: "Aufgabe", context: ""};

async function storeOverActivities() {
  const database = connectRuntimeDatabase(":memory:");
  await database.run(sql`CREATE TABLE activities (
    id TEXT PRIMARY KEY, team_id TEXT NOT NULL, run_id TEXT NOT NULL, task_id TEXT NOT NULL,
    node_id TEXT, target TEXT NOT NULL, primitive TEXT, title TEXT NOT NULL, status TEXT NOT NULL,
    input TEXT NOT NULL DEFAULT '', output TEXT NOT NULL DEFAULT '', outputs_json TEXT NOT NULL DEFAULT '{}',
    message TEXT NOT NULL DEFAULT '', console_json TEXT NOT NULL DEFAULT '{}', duration_ms INTEGER,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )`);
  return {database, store: new SQLiteActivityStore(database)};
}

const result = (overrides: Partial<NodeExecutionResult>): NodeExecutionResult => ({
  nodeId: "node.1", primitive: "script", status: "executed", outputs: {}, ...overrides,
});

test("speichert stdout und stderr eines Bausteins in seiner Aktivität", async () => {
  const {database, store} = await storeOverActivities();

  await store.writeNodeActivities("team-1", run, [
    result({console: {stdout: "Passwort: abc\n", stderr: "Warnung\n"}}),
  ]);

  const [row] = await database.select().from(activities);
  assert.deepEqual(JSON.parse(row.console_json), {stdout: "Passwort: abc\n", stderr: "Warnung\n"});
  database.$client.close();
});

test("ein Baustein ohne Ausgabe speichert eine leere Konsole", async () => {
  const {database, store} = await storeOverActivities();

  await store.writeNodeActivities("team-1", run, [result({primitive: "prompt"})]);

  const [row] = await database.select().from(activities);
  assert.deepEqual(JSON.parse(row.console_json), {});
  database.$client.close();
});
