import {eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {activities, tasks, taskRuns, teams} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {SQLiteActivityStore} from "./sqlite-activity-store.js";
import {SQLiteTaskDefinitionStore} from "./sqlite-task-definition-store.js";
import {taskActivityRoutes} from "./local-task-activity-routes.js";

const run = {runId: "run-1", taskId: "task-1", taskTitle: "Historischer Titel", context: ""};
const activityBody = {id: "activity-1", runId: run.runId, taskId: run.taskId, taskTitle: run.taskTitle,
  target: "task", status: "succeeded", occurredAt: "2026-01-01T10:00:00.000Z", outputs: {value: 42}};

async function fixture(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(teams).values({id: "team-2", name: "Zweites Team", owner_uid: "user-2"});
  await database.insert(tasks).values({id: run.taskId, team_id: "team-1", title: "Aktueller Titel",
    graph_json: "{}", created_by_uid: "user-1"});
  await database.insert(taskRuns).values([1, 2].map((id) => ({id: `run-${id}`, team_id: `team-${id}`,
    task_id: `task-${id}`, task_title: run.taskTitle, status: "running"})));
  return {database, store: new SQLiteActivityStore(database), routes: testingRoutes(taskActivityRoutes, {database})};
}

test("HTTP rejects a foreign run, missing run or contradictory task without storing activities", async (t) => {
  const {database, routes} = await fixture(t);
  for (const override of [{runId: "run-2"}, {runId: "missing"}, {taskId: "task-2"}]) {
    const response = await routes.handle({method: "POST", url: "/v1/activities", body: {...activityBody, ...override}});
    assert.equal(response?.statusCode, 400);
  }
  assert.deepEqual(await database.select().from(activities), []);
});

test("activity listing derives the task through the run and keeps other teams private", async (t) => {
  const {database, store, routes} = await fixture(t);
  await store.writeTaskActivity("team-2", {run: {...run, runId: "run-2", taskId: "task-2"}, status: "succeeded"});
  assert.equal((await routes.handle({method: "POST", url: "/v1/activities", body: activityBody}))?.statusCode, 201);
  const listed = await routes.handle({method: "GET", url: "/v1/activities", body: {}});
  const items = (listed?.body as {items: {id: string; taskId: string; taskTitle: string; outputs: unknown}[]}).items;
  assert.equal(items.length, 1);
  assert.equal(items[0].taskId, run.taskId);
  assert.equal(items[0].taskTitle, run.taskTitle);
  assert.deepEqual(items[0].outputs, activityBody.outputs);
  const columns = await database.all<{name: string}>(sql`PRAGMA table_info(activities)`);
  assert.ok(!columns.some((column) => ["team_id", "task_id"].includes(column.name)));
});

test("all store write paths validate team, run and task ownership", async (t) => {
  const {database, store} = await fixture(t);
  const node = {nodeId: "node-1", primitive: "script" as const, status: "executed" as const, outputs: {}};
  await assert.rejects(store.writeNodeActivities("team-2", run, [node]));
  await assert.rejects(store.writeFailedNodeActivity("team-1", {...run, taskId: "wrong"},
    {nodeId: "node-1", primitive: "script", message: "Fehler"}));
  await assert.rejects(store.writeTaskActivity("team-1", {run: {...run, runId: "missing"}, status: "failed"}));
  assert.deepEqual(await database.select().from(activities), []);
});

test("task changes and deletion preserve activity snapshots; run deletion removes its activities", async (t) => {
  const {database, store, routes} = await fixture(t);
  await store.writeTaskActivity("team-1", {run, status: "succeeded", input: "historisch"});
  await database.update(tasks).set({title: "Neuer Titel"}).where(eq(tasks.id, run.taskId));
  await new SQLiteTaskDefinitionStore(database).delete("team-1", run.taskId);
  const listed = await routes.handle({method: "GET", url: "/v1/activities", body: {}});
  assert.equal((listed?.body as {items: {taskTitle: string}[]}).items[0].taskTitle, run.taskTitle);
  assert.equal((await database.select().from(activities))[0].input, "historisch");
  await database.delete(taskRuns).where(eq(taskRuns.id, run.runId));
  assert.deepEqual(await database.select().from(activities), []);
});

test("the database rejects an activity without an existing run", async (t) => {
  const {database} = await fixture(t);
  await assert.rejects(database.insert(activities).values({id: "orphan", run_id: "missing",
    target: "task", title: "Titel", status: "failed"}));
});
