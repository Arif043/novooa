import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {activities, taskRuns} from "../../../../db/schema.js";
import {type NodeExecutionResult} from "../../domain/entities/task.js";
import {SQLiteActivityStore} from "./sqlite-activity-store.js";

const run = {runId: "run-1", taskId: "task-1", taskTitle: "Aufgabe", context: ""};

async function storeOverActivities(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(taskRuns).values({id: run.runId, task_id: run.taskId, team_id: "team-1",
    task_title: run.taskTitle, status: "running"});
  return {database, store: new SQLiteActivityStore(database)};
}

const result = (overrides: Partial<NodeExecutionResult>): NodeExecutionResult => ({
  nodeId: "node.1", primitive: "script", status: "executed", outputs: {}, ...overrides,
});

test("speichert stdout und stderr eines Bausteins in seiner Aktivität", async (t) => {
  const {database, store} = await storeOverActivities(t);

  await store.writeNodeActivities("team-1", run, [
    result({console: {stdout: "Passwort: abc\n", stderr: "Warnung\n"}}),
  ]);

  const [row] = await database.select().from(activities);
  assert.deepEqual(JSON.parse(row.console_json), {stdout: "Passwort: abc\n", stderr: "Warnung\n"});
});

test("ein Baustein ohne Ausgabe speichert eine leere Konsole", async (t) => {
  const {database, store} = await storeOverActivities(t);

  await store.writeNodeActivities("team-1", run, [result({primitive: "prompt"})]);

  const [row] = await database.select().from(activities);
  assert.deepEqual(JSON.parse(row.console_json), {});
});

test("ein fehlgeschlagener Baustein steht mit Meldung und Ausgabe an seiner Position nach den erfolgreichen", async (t) => {
  const {database, store} = await storeOverActivities(t);

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
});

test("die Zeitstempel einer Reihe von Aktivitäten steigen streng, auch im selben Moment", async (t) => {
  const {database, store} = await storeOverActivities(t);

  await store.writeNodeActivities("team-1", run, Array.from({length: 25}, (_, index) => result({nodeId: `n${index}`})));

  const stamps = (await database.select().from(activities)).map((row) => row.created_at);
  assert.equal(new Set(stamps).size, 25);
  assert.deepEqual([...stamps].sort(), stamps);
});

test("speichert das Gespräch einer Teamarbeit an ihrer Aktivität, auch wenn sie scheitert", async (t) => {
  const {database, store} = await storeOverActivities(t);
  const conversation = [
    {kind: "task" as const, occurredAt: "2026-10-19T08:00:00.000Z", memberName: "Elektriker", text: "Prüfe.", expectedResult: "Ja/Nein"},
    {kind: "answer" as const, occurredAt: "2026-10-19T08:00:05.000Z", memberName: "Elektriker", text: "Ja.", durationMs: 5000},
  ];

  await store.writeNodeActivities("team-1", run, [result({primitive: "teamwork", conversation})]);
  await store.writeFailedNodeActivity("team-1", run, {nodeId: "zwei", primitive: "teamwork", message: "Schema", conversation});

  const rows = await database.select().from(activities).orderBy(activities.created_at);
  assert.deepEqual(rows.map((row) => JSON.parse(row.conversation_json) as unknown), [conversation, conversation]);
});
