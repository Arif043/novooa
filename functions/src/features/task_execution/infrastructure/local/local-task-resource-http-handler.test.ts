import assert from "node:assert/strict";
import test from "node:test";
import {SqliteLocalSqlDatabase} from "../../../../shared/local/sqlite-local-sql-database.js";
import {LocalTaskActivityHttpHandler} from "./local-task-activity-http-handler.js";
import {LocalTaskDefinitionHttpHandler} from "./local-task-definition-http-handler.js";

test("stores and lists a local task definition", async () => {
  const database = await databaseWithTaskTables();
  const handler = new LocalTaskDefinitionHttpHandler(database, "team-1", "user-1");

  const saved = await handler.handle({body: taskBody(), method: "PUT", url: "/v1/tasks/task-1"});
  const listed = await handler.handle({body: {}, method: "GET", url: "/v1/tasks"});

  assert.equal(saved?.statusCode, 200);
  assert.deepEqual(listed, {body: {items: [taskBody()]}, statusCode: 200});
  database.close();
});

test("lists local task runs and activities", async () => {
  const database = await databaseWithTaskTables();
  await database.run(
    "INSERT INTO task_runs(id, team_id, task_id, task_title, status, final_output, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
    ["run-1", "team-1", "task-1", "Aufgabe", "succeeded", "Fertig", "2026-09-08 10:00:00", "2026-09-08 10:01:00"],
  );
  await database.run(
    "INSERT INTO activities(id, team_id, run_id, task_id, target, title, status, outputs_json, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
    ["activity-1", "team-1", "run-1", "task-1", "task", "Aufgabe", "succeeded", "{}", "2026-09-08 10:01:00"],
  );
  const handler = new LocalTaskActivityHttpHandler(database, "team-1");

  const runs = await handler.handle({body: {}, method: "GET", url: "/v1/task-runs"});
  const activities = await handler.handle({body: {}, method: "GET", url: "/v1/activities"});

  assert.equal((runs?.body as {items: Array<{runId: string}>}).items[0]?.runId, "run-1");
  assert.equal((activities?.body as {items: Array<{id: string}>}).items[0]?.id, "activity-1");
  database.close();
});

async function databaseWithTaskTables(): Promise<SqliteLocalSqlDatabase> {
  const database = new SqliteLocalSqlDatabase(":memory:");
  await database.run(`CREATE TABLE tasks (
    id TEXT PRIMARY KEY, team_id TEXT NOT NULL, title TEXT NOT NULL, objective TEXT NOT NULL,
    graph_json TEXT NOT NULL, selected_node_id TEXT NOT NULL, created_by_uid TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )`);
  await database.run(`CREATE TABLE task_runs (
    id TEXT PRIMARY KEY, team_id TEXT NOT NULL, task_id TEXT NOT NULL, task_title TEXT NOT NULL,
    status TEXT NOT NULL, waiting_node_id TEXT, final_output TEXT NOT NULL DEFAULT '', review_output TEXT,
    interaction_json TEXT, error_json TEXT, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )`);
  await database.run(`CREATE TABLE activities (
    id TEXT PRIMARY KEY, team_id TEXT NOT NULL, run_id TEXT NOT NULL, task_id TEXT NOT NULL,
    node_id TEXT, target TEXT NOT NULL, primitive TEXT, title TEXT NOT NULL, status TEXT NOT NULL,
    input TEXT NOT NULL DEFAULT '', output TEXT NOT NULL DEFAULT '', outputs_json TEXT NOT NULL DEFAULT '{}',
    message TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
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
        referenceName: "text",
        config: {primitive: "stringInput", value: "Hallo"},
      }],
      edges: [],
    },
  };
}
