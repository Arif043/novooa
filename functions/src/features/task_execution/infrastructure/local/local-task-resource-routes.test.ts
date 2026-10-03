import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {connectRuntimeDatabase, RuntimeDatabase} from "../../../../db/database.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {type TaskDefinition} from "../../domain/entities/task.js";
import {type TaskDefinitionStore} from "../../domain/repositories/task-definition-store.js";
import {permissiveCycleGuard} from "../../../scheduling/domain/usecases/trigger-cycle-guard-test-support.js";
import {taskActivityRoutes} from "./local-task-activity-routes.js";
import {taskDefinitionRoutes} from "./local-task-definition-routes.js";
import {SQLiteTaskDefinitionStore} from "./sqlite-task-definition-store.js";

test("stores and lists a local task definition", async () => {
  const database = await databaseWithTaskTables();
  const handler = testingRoutes(taskDefinitionRoutes, {store: new SQLiteTaskDefinitionStore(database), notifier: new LocalRuntimeRealtimeNotifier(), cycleGuard: permissiveCycleGuard});

  const saved = await handler.handle({body: taskBody(), method: "PUT", url: "/v1/tasks/task-1"});
  const listed = await handler.handle({body: {}, method: "GET", url: "/v1/tasks"});

  assert.equal(saved?.statusCode, 200);
  assert.deepEqual(listed, {body: {items: [taskBody()]}, statusCode: 200});
  database.$client.close();
});

test("stores an empty local task definition", async () => {
  const database = await databaseWithTaskTables();
  const handler = testingRoutes(taskDefinitionRoutes, {store: new SQLiteTaskDefinitionStore(database), notifier: new LocalRuntimeRealtimeNotifier(), cycleGuard: permissiveCycleGuard});
  const draft = {
    id: "draft-1",
    title: "Neue Aufgabe",
    objective: "",
    selectedNodeId: "",
    graph: {nodes: [], edges: []},
  };

  const response = await handler.handle({body: draft, method: "PUT", url: "/v1/tasks/draft-1"});

  assert.deepEqual(response, {body: draft, statusCode: 200});
  database.$client.close();
});

test("uses the task definition store without a SQL dependency", async () => {
  const store = new MemoryTaskDefinitionStore();
  const handler = testingRoutes(taskDefinitionRoutes, {store: store, notifier: new LocalRuntimeRealtimeNotifier(), cycleGuard: permissiveCycleGuard});

  const saved = await handler.handle({body: taskBody(), method: "PUT", url: "/v1/tasks/task-1"});
  const listed = await handler.handle({body: {}, method: "GET", url: "/v1/tasks"});

  assert.equal(saved?.statusCode, 200);
  assert.deepEqual(listed, {body: {items: [taskBody()]}, statusCode: 200});
});

test("a node activity carries what the script printed to stdout and stderr", async () => {
  const database = await databaseWithTaskTables();
  await database.run(sql`INSERT INTO activities(id, team_id, run_id, task_id, node_id, target, title, status, console_json, created_at) VALUES (${"a-1"}, ${"team-1"}, ${"run-1"}, ${"task-1"}, ${"node.1"}, ${"node"}, ${"node.1"}, ${"succeeded"}, ${'{"stdout":"hallo\\n","stderr":"warnung\\n"}'}, ${"2026-09-08 10:01:00"})`);
  await database.run(sql`INSERT INTO activities(id, team_id, run_id, task_id, target, title, status, created_at) VALUES (${"a-2"}, ${"team-1"}, ${"run-1"}, ${"task-1"}, ${"task"}, ${"Aufgabe"}, ${"succeeded"}, ${"2026-09-08 10:02:00"})`);
  const handler = testingRoutes(taskActivityRoutes, {database});

  const response = await handler.handle({body: {}, method: "GET", url: "/v1/activities"});

  const items = (response?.body as {items: Array<{id: string; console: unknown}>}).items;
  assert.deepEqual(items.find((item) => item.id === "a-1")?.console, {stdout: "hallo\n", stderr: "warnung\n"});
  assert.deepEqual(items.find((item) => item.id === "a-2")?.console, {stdout: "", stderr: ""});
  database.$client.close();
});

test("lists local task runs and activities", async () => {
  const database = await databaseWithTaskTables();
  await database.run(sql`INSERT INTO task_runs(id, team_id, task_id, task_title, status, final_output, created_at, updated_at) VALUES (${"run-1"}, ${"team-1"}, ${"task-1"}, ${"Aufgabe"}, ${"succeeded"}, ${"Fertig"}, ${"2026-09-08 10:00:00"}, ${"2026-09-08 10:01:00"})`);
  await database.run(sql`INSERT INTO activities(id, team_id, run_id, task_id, target, title, status, outputs_json, created_at) VALUES (${"activity-1"}, ${"team-1"}, ${"run-1"}, ${"task-1"}, ${"task"}, ${"Aufgabe"}, ${"succeeded"}, ${"{}"}, ${"2026-09-08 10:01:00"})`);
  const handler = testingRoutes(taskActivityRoutes, {database});

  const runs = await handler.handle({body: {}, method: "GET", url: "/v1/task-runs"});
  const activities = await handler.handle({body: {}, method: "GET", url: "/v1/activities"});

  assert.equal((runs?.body as {items: Array<{runId: string}>}).items[0]?.runId, "run-1");
  assert.equal((activities?.body as {items: Array<{id: string}>}).items[0]?.id, "activity-1");
  database.$client.close();
});

async function databaseWithTaskTables(): Promise<RuntimeDatabase> {
  const database = connectRuntimeDatabase(":memory:");
  await database.run(sql`CREATE TABLE tasks (
    id TEXT PRIMARY KEY, team_id TEXT NOT NULL, title TEXT NOT NULL, objective TEXT NOT NULL,
    graph_json TEXT NOT NULL, selected_node_id TEXT NOT NULL, created_by_uid TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )`);
  await database.run(sql`CREATE TABLE task_runs (
    id TEXT PRIMARY KEY, team_id TEXT NOT NULL, task_id TEXT NOT NULL, task_title TEXT NOT NULL,
    status TEXT NOT NULL, waiting_node_id TEXT, final_output TEXT NOT NULL DEFAULT '', review_output TEXT,
    interaction_json TEXT, error_json TEXT, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )`);
  await database.run(sql`CREATE TABLE activities (
    id TEXT PRIMARY KEY, team_id TEXT NOT NULL, run_id TEXT NOT NULL, task_id TEXT NOT NULL,
    node_id TEXT, target TEXT NOT NULL, primitive TEXT, title TEXT NOT NULL, status TEXT NOT NULL,
    input TEXT NOT NULL DEFAULT '', output TEXT NOT NULL DEFAULT '', outputs_json TEXT NOT NULL DEFAULT '{}',
    message TEXT NOT NULL DEFAULT '', console_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )`);
  return database;
}

function taskBody() {
  return {
    id: "task-1",
    title: "Aufgabe",
    objective: "",
    selectedNodeId: "node-1",
    graph: {
      nodes: [{
        id: "node-1",
        primitive: "stringInput",
        title: "Text",
        description: "",
        outputName: "text",
        config: {primitive: "stringInput", value: "Hallo"},
      }],
      edges: [],
    },
  };
}

class MemoryTaskDefinitionStore implements TaskDefinitionStore {
  readonly items = new Map<string, TaskDefinition>();
  readonly selectedNodeIds = new Map<string, string>();

  async delete(_teamId: string, taskId: string): Promise<void> {
    this.items.delete(taskId);
  }

  async list(_teamId: string): Promise<TaskDefinition[]> {
    return [...this.items.values()];
  }

  async save(_teamId: string, _userId: string, definition: TaskDefinition, selectedNodeId: string): Promise<void> {
    this.items.set(definition.id, definition);
    this.selectedNodeIds.set(definition.id, selectedNodeId);
  }

  async selectedNodeId(_teamId: string, taskId: string): Promise<string> {
    return this.selectedNodeIds.get(taskId) ?? "";
  }
}
