import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test, {type TestContext} from "node:test";
import {eq} from "drizzle-orm";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {fileFolders, fileVersions} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {type FileEvent} from "../../domain/entities/file-event.js";
import {fileMutationRoutes} from "./local-file-mutation-routes.js";
import {SQLiteFileSettingsStore} from "./sqlite-file-settings-store.js";
import {SQLiteTeamFileMutations} from "./sqlite-team-file-mutations.js";
import {SQLiteTeamFileStore} from "./sqlite-team-file-store.js";

type FileBody = {id: string; displayName: string; folderId: string | null; currentVersionId: string; sizeBytes: number};

async function setUp(t: TestContext) {
  const root = await mkdtemp(path.join(os.tmpdir(), "novooa-file-mutations-"));
  const database = await runtimeTestDatabase(t);
  const events: FileEvent[] = [];
  const store = new SQLiteTeamFileStore(database, root, new SQLiteFileSettingsStore(database), {publish: async (event) => {
    events.push(event);
  }});
  const routes = testingRoutes(fileMutationRoutes, {
    database, mutations: new SQLiteTeamFileMutations(database, store), notifier: new LocalRuntimeRealtimeNotifier(),
  });
  t.after(async () => {
    database.$client.close();
    await rm(root, {force: true, recursive: true});
  });
  const write = (fileName: string, content: string, folderId: string | null = null) => store.writeTeamFile({
    teamId: "team-1", fileName, contentType: "text/plain", content, folderId, targetFileId: null,
  });
  const versionCount = async (fileId: string) =>
    (await database.select().from(fileVersions).where(eq(fileVersions.file_id, fileId))).length;
  const folder = async (id: string) => {
    await database.insert(fileFolders).values({id, root_team_id: "team-1", parent_folder_id: null, owner_uid: "user-1", name: id});
  };
  return {routes, write, store, events, versionCount, folder};
}

test("renaming changes only the name; versions and content stay", async (t) => {
  const {routes, write, versionCount} = await setUp(t);
  const file = await write("notiz.txt", "Hallo");

  const renamed = await routes.handle({method: "PATCH", url: `/v1/files/${file.fileId}`, body: {name: "Protokoll.txt"}});

  assert.equal(renamed?.statusCode, 200);
  assert.equal((renamed?.body as FileBody).displayName, "Protokoll.txt");
  assert.equal((renamed?.body as FileBody).currentVersionId, file.versionId);
  assert.equal(await versionCount(file.fileId), 1);
});

test("a name already used in the folder is a conflict, a missing folder a bad request", async (t) => {
  const {routes, write} = await setUp(t);
  await write("a.txt", "1");
  const second = await write("b.txt", "2");

  const conflict = await routes.handle({method: "PATCH", url: `/v1/files/${second.fileId}`, body: {name: "a.txt"}});
  const missingFolder = await routes.handle({method: "PATCH", url: `/v1/files/${second.fileId}`, body: {folderId: "gibt-es-nicht"}});
  const missingFile = await routes.handle({method: "PATCH", url: "/v1/files/gibt-es-nicht", body: {name: "c.txt"}});

  assert.equal(conflict?.statusCode, 409);
  assert.equal(missingFolder?.statusCode, 400);
  assert.equal(missingFile?.statusCode, 404);
});

test("moving puts the file into a folder and back to the top level", async (t) => {
  const {routes, write, folder} = await setUp(t);
  await folder("archiv");
  const file = await write("a.txt", "1");

  const moved = await routes.handle({method: "PATCH", url: `/v1/files/${file.fileId}`, body: {folderId: "archiv"}});
  const back = await routes.handle({method: "PATCH", url: `/v1/files/${file.fileId}`, body: {folderId: null}});

  assert.equal((moved?.body as FileBody).folderId, "archiv");
  assert.equal((back?.body as FileBody).folderId, null);
});

test("a copy is a new file with the current content and a free name", async (t) => {
  const {routes, write, versionCount, events} = await setUp(t);
  const source = await write("Bericht.txt", "Stand 1");
  await write("Bericht (Kopie).txt", "andere Datei");

  const copied = await routes.handle({method: "POST", url: `/v1/files/${source.fileId}/copy`, body: {name: "Bericht (Kopie).txt"}});

  const copy = copied?.body as FileBody;
  assert.equal(copied?.statusCode, 201);
  assert.notEqual(copy.id, source.fileId);
  assert.equal(copy.displayName, "Bericht (Kopie) (2).txt");
  assert.equal(copy.sizeBytes, "Stand 1".length);
  assert.equal(await versionCount(source.fileId), 1, "the source gets no new version");
  assert.equal(events[events.length - 1]?.type, "fileCreated");
});

test("restoring an old version makes its content the new current version", async (t) => {
  const {routes, write, store, versionCount, events} = await setUp(t);
  const first = await write("notiz.txt", "alt");
  await store.writeTeamFile({teamId: "team-1", fileName: "notiz.txt", contentType: "text/plain", content: "neu", targetFileId: first.fileId});

  const restored = await routes.handle({
    method: "POST", url: `/v1/files/${first.fileId}/versions/${first.versionId}/restore`, body: {},
  });
  const current = (restored?.body as FileBody).currentVersionId;
  const content = await store.readTeamFileContent("team-1", first.fileId, current);

  assert.equal(restored?.statusCode, 200);
  assert.notEqual(current, first.versionId, "a new version, the old one stays untouched");
  assert.equal(Buffer.from(content.content).toString(), "alt");
  assert.equal(await versionCount(first.fileId), 3);
  assert.equal(events[events.length - 1]?.type, "fileVersionCreated");
});

test("restoring a version of another file is not found", async (t) => {
  const {routes, write} = await setUp(t);
  const first = await write("a.txt", "1");
  const second = await write("b.txt", "2");

  const restored = await routes.handle({
    method: "POST", url: `/v1/files/${second.fileId}/versions/${first.versionId}/restore`, body: {},
  });

  assert.equal(restored?.statusCode, 404);
});
