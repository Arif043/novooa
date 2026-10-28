import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {taskRuns} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {type NodeExecutionResult} from "../../domain/entities/task.js";
import {taskActivityRoutes} from "./local-task-activity-routes.js";
import {taskRunGraphRoutes} from "./local-task-run-graph-routes.js";
import {SQLiteActivityStore} from "./sqlite-activity-store.js";

const run = {runId: "run-1", taskId: "task-1", taskTitle: "Aufgabe", context: ""};
type ActivityBody = {nodeId: string; parentNodeId: string | null; iteration: number | null; selectedBranchId: string | null; status: string};

const executed = (nodeId: string, overrides: Partial<NodeExecutionResult> = {}): NodeExecutionResult => ({
  nodeId, primitive: "stringInput", status: "executed", outputs: {value: {type: "string", value: nodeId}}, ...overrides,
});

async function withRun(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(taskRuns).values({id: run.runId, task_id: run.taskId, team_id: "team-1", task_title: run.taskTitle,
    status: "succeeded", started_at: "2026-10-28 10:00:00", completed_at: "2026-10-28 10:00:04"});
  const store = new SQLiteActivityStore(database);
  await store.writeNodeActivities("team-1", run, [
    executed("liste"),
    executed("schleife", {primitive: "forEach", nested: [
      {iteration: 0, results: [executed("schritt")]},
      {iteration: 1, results: [executed("weiche", {primitive: "conditionalFlow", selectedBranchId: "ja",
        nested: [{results: [executed("ja-text")]}]})]},
    ]}),
  ]);
  await store.writeFailedNodeActivity("team-1", run, {nodeId: "ende", primitive: "forEach", message: "Abbruch",
    nested: [{iteration: 0, results: [], failed: {nodeId: "innen", primitive: "stringInput", message: "kaputt"}}]});
  return database;
}

const items = (response: {body: object} | null) => (response?.body as {items: ActivityBody[]}).items;

test("a run's activities contain every inner node with its parent, round and chosen branch", async (t) => {
  const database = await withRun(t);

  const listed = items(await testingRoutes(taskRunGraphRoutes, {database})
    .handle({method: "GET", url: "/v1/task-runs/run-1/activities", body: {}}));

  assert.deepEqual(listed.map((item) => [item.nodeId, item.parentNodeId, item.iteration, item.status]), [
    ["liste", null, null, "succeeded"],
    ["schleife", null, null, "succeeded"],
    ["schritt", "schleife", 0, "succeeded"],
    ["weiche", "schleife", 1, "succeeded"],
    ["ja-text", "weiche", null, "succeeded"],
    ["ende", null, null, "failed"],
    ["innen", "ende", 0, "failed"],
  ]);
  assert.equal(listed.find((item) => item.nodeId === "weiche")?.selectedBranchId, "ja");
});

test("the history keeps showing only the top level", async (t) => {
  const database = await withRun(t);

  const history = items(await testingRoutes(taskActivityRoutes, {database}).handle({method: "GET", url: "/v1/activities", body: {}}));

  assert.deepEqual(history.map((item) => item.nodeId).sort(), ["ende", "liste", "schleife"]);
});

test("runs carry start, end and origin for the results page", async (t) => {
  const database = await withRun(t);

  const runs = (await testingRoutes(taskActivityRoutes, {database}).handle({method: "GET", url: "/v1/task-runs", body: {}}))
    ?.body as {items: Array<{startedAt: string; completedAt: string; startedBy: unknown}>};

  assert.equal(runs.items[0]?.startedAt, "2026-10-28T10:00:00Z");
  assert.equal(runs.items[0]?.completedAt, "2026-10-28T10:00:04Z");
  assert.equal(runs.items[0]?.startedBy, null);
});
