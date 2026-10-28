import assert from "node:assert/strict";
import test from "node:test";
import {eq} from "drizzle-orm";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {taskRuns} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {type TaskDefinition} from "../../domain/entities/task.js";
import {taskRunGraphRoutes} from "./local-task-run-graph-routes.js";
import {SQLiteTaskRunStore} from "./sqlite-task-run-store.js";

const silentActivities = {
  writeNodeActivities: async () => {}, writeFailedNodeActivity: async () => {}, writeTaskActivity: async () => {},
};

const task = (title: string): TaskDefinition => ({
  id: "task-1", title, objective: "", edges: [],
  nodes: [{id: "a", primitive: "stringInput", title: "Text", description: "", outputs: [], config: {primitive: "stringInput", value: title}}],
} as unknown as TaskDefinition);

test("a run keeps the graph it started with, also when resumed", async (t) => {
  const database = await runtimeTestDatabase(t);
  const store = new SQLiteTaskRunStore(database, silentActivities, {} as never);

  const run = await store.enqueueTaskRun({teamId: "team-1", task: task("Stand beim Start"), context: ""});
  // Wie nach einer Freigabe: Der Lauf hat einen Zwischenstand und wartet auf die Fortsetzung.
  await database.update(taskRuns)
    .set({resume_state_json: JSON.stringify({nodeResults: [], remainingNodeIds: ["a"], skippedNodeIds: []})})
    .where(eq(taskRuns.id, run.runId));
  const resumable = await store.loadResumableRun("team-1", run.runId);

  assert.equal(resumable.run.graphSnapshot?.title, "Stand beim Start");
  assert.equal((resumable.run.graphSnapshot?.nodes[0]?.config as {value: string}).value, "Stand beim Start");
});

test("an older run without a snapshot simply has none", async (t) => {
  const database = await runtimeTestDatabase(t);
  const store = new SQLiteTaskRunStore(database, silentActivities, {} as never);
  const run = await store.enqueueTaskRun({teamId: "team-1", task: task("Neu"), context: ""});
  await database.update(taskRuns).set({graph_snapshot_json: null}).where(eq(taskRuns.id, run.runId));

  const loaded = await store.loadTaskRun("team-1", run.runId);

  assert.equal(loaded.graphSnapshot, undefined);
});

test("the graph route returns the snapshot, and 404 without one or for another team", async (t) => {
  const database = await runtimeTestDatabase(t);
  const store = new SQLiteTaskRunStore(database, silentActivities, {} as never);
  const routes = testingRoutes(taskRunGraphRoutes, {database});
  const run = await store.enqueueTaskRun({teamId: "team-1", task: task("Graph"), context: ""});

  const found = await routes.handle({method: "GET", url: `/v1/task-runs/${run.runId}/graph`, body: {}});
  await database.update(taskRuns).set({graph_snapshot_json: null}).where(eq(taskRuns.id, run.runId));
  const missing = await routes.handle({method: "GET", url: `/v1/task-runs/${run.runId}/graph`, body: {}});
  const unknown = await routes.handle({method: "GET", url: "/v1/task-runs/gibt-es-nicht/graph", body: {}});

  assert.equal(found?.statusCode, 200);
  assert.equal((found?.body as {title: string}).title, "Graph");
  assert.equal(missing?.statusCode, 404);
  assert.equal(unknown?.statusCode, 404);
});
