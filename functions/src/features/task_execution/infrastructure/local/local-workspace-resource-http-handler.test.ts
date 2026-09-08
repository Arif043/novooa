import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {LocalTeamFileStore} from "../../../files/infrastructure/local/local-team-file-store.js";
import {LocalFileResourceHttpHandler} from "../../../files/infrastructure/local/local-file-resource-http-handler.js";
import {LocalKnowledgeNoteHttpHandler} from "../../../knowledge_base/infrastructure/local/local-knowledge-note-http-handler.js";
import {LocalTaskTriggerHttpHandler} from "../../../scheduling/infrastructure/local/local-task-trigger-http-handler.js";
import {SqliteLocalSqlDatabase} from "../../../../shared/local/sqlite-local-sql-database.js";

test("persists local knowledge notes and task triggers", async () => {
  const database = await databaseForResources();
  const notes = new LocalKnowledgeNoteHttpHandler(database, "team-1");
  const triggers = new LocalTaskTriggerHttpHandler(database, "team-1", "user-1");

  const createdNote = await notes.handle({
    method: "POST", url: "/v1/knowledge-notes",
    body: {title: "Index", path: "index.md", content: "# Index", outgoingLinks: []},
  });
  const createdTrigger = await triggers.handle({
    method: "POST", url: "/v1/task-triggers",
    body: {
      taskId: "task-1", type: "schedule", enabled: true,
      config: {kind: "daily", timezone: "UTC", timeOfDay: "09:00", weekdays: [], slots: []},
      policy: {ifRunning: "skipIfRunning"},
    },
  });

  const listedNotes = await notes.handle({body: {}, method: "GET", url: "/v1/knowledge-notes"});
  const listedTriggers = await triggers.handle({body: {}, method: "GET", url: "/v1/task-triggers"});

  assert.equal(createdNote?.statusCode, 201);
  assert.equal(createdTrigger?.statusCode, 201);
  assert.equal((listedNotes?.body as {items: unknown[]}).items.length, 1);
  assert.equal((listedTriggers?.body as {items: Array<{taskTitle: string}>}).items[0]?.taskTitle, "Aufgabe");
  database.close();
});

test("stores, versions, and reads local files", async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), "novooa-local-files-"));
  const database = await databaseForResources();
  const handler = new LocalFileResourceHttpHandler(
    database,
    new LocalTeamFileStore(database, root),
    "team-1",
    "user-1",
  );

  try {
    const folder = await handler.handle({
      method: "POST", url: "/v1/folders", body: {name: "Notizen"},
    });
    const folderId = (folder?.body as {id: string}).id;
    const uploaded = await handler.handle({
      method: "POST", url: "/v1/files",
      body: {name: "notiz.txt", contentType: "text/plain", contentBase64: "SGFsbG8=", folderId},
    });
    const fileId = (uploaded?.body as {id: string}).id;
    const versionId = (uploaded?.body as {currentVersionId: string}).currentVersionId;
    const content = await handler.handle({
      body: {}, method: "GET", url: `/v1/files/${fileId}/versions/${versionId}/content`,
    });

    assert.equal(uploaded?.statusCode, 201);
    assert.deepEqual(content, {body: {contentBase64: "SGFsbG8="}, statusCode: 200});
  } finally {
    database.close();
    await rm(root, {force: true, recursive: true});
  }
});

async function databaseForResources(): Promise<SqliteLocalSqlDatabase> {
  const database = new SqliteLocalSqlDatabase(":memory:");
  await database.run("CREATE TABLE tasks (id TEXT PRIMARY KEY, team_id TEXT, title TEXT)");
  await database.run(`CREATE TABLE task_triggers (
    id TEXT PRIMARY KEY, team_id TEXT, task_id TEXT, type TEXT, enabled INTEGER,
    config_json TEXT, event_config_json TEXT, policy_json TEXT, next_run_at TEXT,
    last_run_at TEXT, last_run_id TEXT, created_by_uid TEXT, updated_at TEXT
  )`);
  await database.run(`CREATE TABLE knowledge_notes (
    id TEXT PRIMARY KEY, team_id TEXT, knowledge_base_id TEXT, title TEXT, path TEXT,
    content TEXT, outgoing_links_json TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
  )`);
  await database.run(`CREATE TABLE file_folders (
    id TEXT PRIMARY KEY, team_id TEXT, owner_uid TEXT, name TEXT, parent_folder_id TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT DEFAULT CURRENT_TIMESTAMP
  )`);
  await database.run(`CREATE TABLE files (
    id TEXT PRIMARY KEY, team_id TEXT, owner_uid TEXT, display_name TEXT, folder_id TEXT,
    current_version_id TEXT, content_type TEXT, size_bytes INTEGER, storage_path TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT DEFAULT CURRENT_TIMESTAMP
  )`);
  await database.run(`CREATE TABLE file_versions (
    id TEXT PRIMARY KEY, team_id TEXT, file_id TEXT, created_by_uid TEXT, display_name TEXT,
    storage_path TEXT, content_type TEXT, size_bytes INTEGER, created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )`);
  await database.run("INSERT INTO tasks(id, team_id, title) VALUES (?, ?, ?)", ["task-1", "team-1", "Aufgabe"]);
  return database;
}
