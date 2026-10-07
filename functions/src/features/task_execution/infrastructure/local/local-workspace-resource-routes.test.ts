import assert from "node:assert/strict";
import {access, mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test, {type TestContext} from "node:test";
import {eq} from "drizzle-orm";
import {type FileEvent} from "../../../files/domain/entities/file-event.js";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {fileVersions, tasks} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {fileResourceRoutes} from "../../../files/infrastructure/local/local-file-resource-routes.js";
import {SQLiteFileSettingsStore} from "../../../files/infrastructure/local/sqlite-file-settings-store.js";
import {SQLiteTeamFileStore} from "../../../files/infrastructure/local/sqlite-team-file-store.js";
import {knowledgeNoteRoutes} from "../../../knowledge_base/infrastructure/local/local-knowledge-note-routes.js";
import {cycleGuardFor} from "../../../scheduling/domain/usecases/trigger-cycle-guard-test-support.js";
import {webhookSecretsFor} from "../../../scheduling/infrastructure/local/webhook-secrets-test-support.js";
import {taskTriggerRoutes} from "../../../scheduling/infrastructure/local/local-task-trigger-routes.js";

test("persists local knowledge notes and task triggers", async (t) => {
  const database = await databaseForResources(t);
  const notes = testingRoutes(knowledgeNoteRoutes, {database, notifier: new LocalRuntimeRealtimeNotifier()});
  const triggers = testingRoutes(taskTriggerRoutes, {database, notifier: new LocalRuntimeRealtimeNotifier(), cycleGuard: cycleGuardFor(database), webhookSecrets: webhookSecretsFor(database)});

  const createdNote = await notes.handle({
    method: "POST", url: "/v1/knowledge-notes",
    body: {title: "Index", path: "index.md", content: "# Index"},
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
  database.$client.close();
});

test("stores, versions, and reads local files", async (t) => {
  const root = await mkdtemp(path.join(os.tmpdir(), "novooa-local-files-"));
  const database = await databaseForResources(t);
  const handler = testingRoutes(fileResourceRoutes, {
    database, fileStore: new SQLiteTeamFileStore(database, root, new SQLiteFileSettingsStore(database)), notifier: new LocalRuntimeRealtimeNotifier(),
  });

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

    const traversal = await handler.handle({
      method: "POST", url: "/v1/files", body: {name: "../geheim.txt", contentBase64: "SGFsbG8="},
    });

    assert.equal(uploaded?.statusCode, 201);
    assert.deepEqual(content, {body: {contentBase64: "SGFsbG8="}, statusCode: 200});
    assert.equal(traversal?.statusCode, 400, "Dateinamen mit Pfadanteil lehnt das Schema ab");
  } finally {
    database.$client.close();
    await rm(root, {force: true, recursive: true});
  }
});

test("rotates local file versions beyond the configured limit", async (t) => {
  const root = await mkdtemp(path.join(os.tmpdir(), "novooa-local-rotation-"));
  const database = await databaseForResources(t);
  const settings = new SQLiteFileSettingsStore(database);
  await settings.saveVersionLimit("team-1", 2);
  const store = new SQLiteTeamFileStore(database, root, settings);

  try {
    const first = await store.writeTeamFile({
      teamId: "team-1", fileName: "notiz.txt", contentType: "text/plain", content: "1", targetFileId: null,
    });
    await store.writeTeamFile({
      teamId: "team-1", fileName: "notiz.txt", contentType: "text/plain", content: "2", targetFileId: first.fileId,
    });
    const third = await store.writeTeamFile({
      teamId: "team-1", fileName: "notiz.txt", contentType: "text/plain", content: "3", targetFileId: first.fileId,
    });

    const rows = await database.select().from(fileVersions).where(eq(fileVersions.file_id, first.fileId));
    assert.equal(rows.length, 2);
    assert.ok(rows.some((row) => row.id === third.versionId), "aktuelle Version bleibt erhalten");
    await assert.rejects(access(path.join(root, first.storagePath)), "Datei der rotierten Version ist entfernt");
    await access(path.join(root, third.storagePath));
  } finally {
    database.$client.close();
    await rm(root, {force: true, recursive: true});
  }
});

test("publishes file events and deletes a file with all versions", async (t) => {
  const root = await mkdtemp(path.join(os.tmpdir(), "novooa-local-file-events-"));
  const database = await databaseForResources(t);
  const events: FileEvent[] = [];
  const store = new SQLiteTeamFileStore(database, root, new SQLiteFileSettingsStore(database), {
    publish: async (event) => {events.push(event);},
  });

  try {
    const first = await store.writeTeamFile({
      teamId: "team-1", fileName: "notiz.txt", contentType: "text/plain", content: "1", targetFileId: null,
      triggerChain: ["trigger-a"],
    });
    await store.writeTeamFile({
      teamId: "team-1", fileName: "notiz.txt", contentType: "text/plain", content: "2", targetFileId: first.fileId,
    });
    const deleted = await store.deleteTeamFile("team-1", first.fileId);
    const missing = await store.deleteTeamFile("team-1", first.fileId);

    assert.deepEqual(events.map((event) => event.type), ["fileCreated", "fileVersionCreated", "fileDeleted"]);
    assert.deepEqual(events[0].triggerChain, ["trigger-a"]);
    assert.deepEqual(events[1].triggerChain, []);
    assert.equal(events[2].displayName, "notiz.txt");
    assert.equal(events[2].versionId, null);
    assert.equal(deleted, true);
    assert.equal(missing, false);
    assert.equal((await database.select().from(fileVersions).where(eq(fileVersions.file_id, first.fileId))).length, 0);
    await assert.rejects(access(path.join(root, first.storagePath)));
  } finally {
    database.$client.close();
    await rm(root, {force: true, recursive: true});
  }
});

async function databaseForResources(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(tasks).values({id: "task-1", team_id: "team-1", title: "Aufgabe", graph_json: "{}", created_by_uid: "user-1"});
  return database;
}
