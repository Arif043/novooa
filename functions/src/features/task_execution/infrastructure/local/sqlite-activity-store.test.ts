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

test("ein fehlgeschlagener Baustein steht mit Meldung und Ausgabe an seiner Position nach den erfolgreichen", async () => {
  const {database, store} = await storeOverActivities();

  await store.writeNodeActivities("team-1", run, [result({nodeId: "eins"}), result({nodeId: "zwei"})]);
  await store.writeFailedNodeActivity("team-1", run, {
    nodeId: "drei", primitive: "script", message: "Zeile 1: NameError", console: {stdout: "davor\n", stderr: "warnung\n"},
  });
  await store.writeTaskActivity("team-1", {run, status: "failed", message: "Zeile 1: NameError"});

  const rows = await database.select().from(activities).orderBy(activities.created_at);
  assert.deepEqual(rows.map((row) => [row.target, row.node_id, row.status]), [
    ["node", "eins", "succeeded"], ["node", "zwei", "succeeded"], ["node", "drei", "failed"], ["task", null, "failed"],
  ]);
  assert.equal(rows[2]?.message, "Zeile 1: NameError");
  assert.deepEqual(JSON.parse(rows[2]?.console_json ?? "{}"), {stdout: "davor\n", stderr: "warnung\n"});
  database.$client.close();
});

test("die Zeitstempel einer Reihe von Aktivitäten steigen streng, auch im selben Moment", async () => {
  const {database, store} = await storeOverActivities();

  await store.writeNodeActivities("team-1", run, Array.from({length: 25}, (_, index) => result({nodeId: `n${index}`})));

  const stamps = (await database.select().from(activities)).map((row) => row.created_at);
  assert.equal(new Set(stamps).size, 25);
  assert.deepEqual([...stamps].sort(), stamps);
  database.$client.close();
});
