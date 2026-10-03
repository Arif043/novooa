import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {connectRuntimeDatabase} from "../../../../db/database.js";
import {type NodeExecutionResult} from "../../domain/entities/task.js";
import {type ActivityStore, type TaskActivityInput} from "../../domain/repositories/activity-store.js";
import {type FailedNode} from "../../domain/services/run-failure-details.js";
import {SQLiteTaskRunStore} from "./sqlite-task-run-store.js";

const run = {runId: "run-1", taskId: "task-1", taskTitle: "Aufgabe", context: ""};

class RecordingActivityStore implements ActivityStore {
  readonly calls: string[] = [];
  nodeResults: NodeExecutionResult[] = [];
  failedNode?: FailedNode;
  taskActivity?: TaskActivityInput;

  async writeNodeActivities(_teamId: string, _run: unknown, results: NodeExecutionResult[]) {
    this.calls.push("nodes");
    this.nodeResults = results;
  }

  async writeFailedNodeActivity(_teamId: string, _run: unknown, failedNode: FailedNode) {
    this.calls.push("failedNode");
    this.failedNode = failedNode;
  }

  async writeTaskActivity(_teamId: string, input: TaskActivityInput) {
    this.calls.push("task");
    this.taskActivity = input;
  }
}

async function storeWith(activityStore: ActivityStore) {
  const database = connectRuntimeDatabase(":memory:");
  await database.run(sql`CREATE TABLE task_runs (
    id TEXT PRIMARY KEY, team_id TEXT NOT NULL, status TEXT NOT NULL, error_json TEXT,
    completed_at TEXT, updated_at TEXT
  )`);
  await database.run(sql`INSERT INTO task_runs(id, team_id, status) VALUES ('run-1', 'team-1', 'running')`);
  return {database, store: new SQLiteTaskRunStore(database, activityStore, {} as never)};
}

const succeeded = (nodeId: string): NodeExecutionResult => ({nodeId, primitive: "script", status: "executed", outputs: {}});

test("a failed run keeps the results of the nodes that succeeded before the failure", async () => {
  const activities = new RecordingActivityStore();
  const {database, store} = await storeWith(activities);

  await store.markRunFailed("team-1", run, new Error("Zeile 2: ValueError: kaputt"), {
    completedNodeResults: [succeeded("eins"), succeeded("zwei")],
    failedNode: {nodeId: "drei", primitive: "script", message: "Zeile 2: ValueError: kaputt", console: {stdout: "vorher\n", stderr: ""}},
  });

  assert.deepEqual(activities.nodeResults.map((result) => result.nodeId), ["eins", "zwei"]);
  assert.equal(activities.failedNode?.nodeId, "drei");
  assert.deepEqual(activities.calls, ["nodes", "failedNode", "task"], "Bausteine in Reihenfolge, dann der Lauf");
  assert.equal(activities.taskActivity?.status, "failed");
  assert.match(activities.taskActivity?.message ?? "", /ValueError: kaputt/);
  database.$client.close();
});

test("a failed run without completed nodes still records the failure", async () => {
  const activities = new RecordingActivityStore();
  const {database, store} = await storeWith(activities);

  await store.markRunFailed("team-1", run, new Error("sofort"));

  assert.deepEqual(activities.nodeResults, []);
  assert.equal(activities.failedNode, undefined);
  assert.equal(activities.taskActivity?.status, "failed");
  database.$client.close();
});
