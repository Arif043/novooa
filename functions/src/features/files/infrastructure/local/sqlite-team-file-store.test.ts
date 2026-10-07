import {eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {files, fileVersions, teams} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {fileResourceRoutes} from "./local-file-resource-routes.js";
import {SQLiteTeamFileStore} from "./sqlite-team-file-store.js";
import {SQLiteFileSettingsStore} from "./sqlite-file-settings-store.js";

async function fixture(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  const root = await mkdtemp(join(tmpdir(), "novooa-normalized-files-"));
  t.after(() => rm(root, {recursive: true, force: true}));
  await database.insert(teams).values({id: "team-2", name: "Andere", owner_uid: "user-2"});
  const store = new SQLiteTeamFileStore(database, root, new SQLiteFileSettingsStore(database));
  const options = {database, fileStore: store, notifier: {publish: () => undefined}};
  const routes = testingRoutes(fileResourceRoutes, options);
  const otherRoutes = testingRoutes(fileResourceRoutes, options, {teamId: "team-2"});
  return {database, store, routes, otherRoutes};
}

function write(store: SQLiteTeamFileStore, content = "Hallo", targetFileId: string | null = null,
  contentType = "text/plain", teamId = "team-1") {
  return store.writeTeamFile({teamId, fileName: "notiz.txt", contentType, content, targetFileId});
}

test("latest metadata comes from its version while older versions retain their metadata", async (t) => {
  const {store, routes} = await fixture(t);
  const first = await write(store);
  const latest = await write(store, "{}", first.fileId, "application/json");
  const loaded = await store.loadTeamFile("team-1", first.fileId);
  assert.equal(loaded.versionId, latest.versionId);
  assert.equal(loaded.contentType, "application/json");
  assert.equal(loaded.sizeBytes, 2);
  assert.equal(loaded.storagePath, latest.storagePath);
  const historical = await store.readTeamFileContent("team-1", first.fileId, first.versionId);
  assert.equal(historical.contentType, "text/plain");
  assert.equal(historical.sizeBytes, 5);
  const response = await routes.handle({url: "/v1/files", body: {}});
  const listed = (response?.body as {items: Array<{currentVersionId: string; sizeBytes: number}>}).items;
  assert.equal(listed[0].currentVersionId, latest.versionId);
  assert.equal(listed[0].sizeBytes, 2);
});

test("version access, writes and deletion preserve team isolation without a version team column", async (t) => {
  const {store, otherRoutes} = await fixture(t);
  const file = await write(store);
  await assert.rejects(store.loadTeamFile("team-2", file.fileId), /Datei nicht gefunden/);
  await assert.rejects(store.readTeamFileContent("team-2", file.fileId, file.versionId), /Dateiversion nicht gefunden/);
  await assert.rejects(write(store, "fremd", file.fileId, "text/plain", "team-2"), /Datei nicht gefunden/);
  assert.equal(await store.deleteTeamFile("team-2", file.fileId), false);
  const response = await otherRoutes.handle({url: `/v1/files/${file.fileId}/versions`, body: {}});
  assert.deepEqual(response?.body, {items: []});
  const content = await store.readTeamFileContent("team-1", file.fileId, file.versionId);
  assert.equal(Buffer.from(content.content).toString(), "Hallo");
});

test("the database rejects current versions belonging to another file", async (t) => {
  const {database, store} = await fixture(t);
  const first = await write(store);
  const other = await write(store, "Andere", null, "text/plain", "team-2");
  await assert.rejects(database.update(files).set({current_version_id: other.versionId})
    .where(eq(files.id, first.fileId)));
  await assert.rejects(database.delete(fileVersions).where(eq(fileVersions.id, first.versionId)));
  assert.equal((await store.loadTeamFile("team-1", first.fileId)).versionId, first.versionId);
  assert.equal(await store.deleteTeamFile("team-1", first.fileId), true);
  assert.equal((await database.select().from(fileVersions).where(eq(fileVersions.file_id, first.fileId))).length, 0);
  assert.equal((await store.loadTeamFile("team-2", other.fileId)).versionId, other.versionId);
});

test("a rejected version insertion rolls back both the version and current-version switch", async (t) => {
  const {database, store} = await fixture(t);
  const file = await write(store);
  await assert.rejects(database.transaction(async (tx) => {
    await tx.update(files).set({current_version_id: null}).where(eq(files.id, file.fileId));
    await tx.insert(fileVersions).values({id: "invalid", file_id: file.fileId, created_by_uid: "system",
      display_name: "invalid", storage_path: "invalid", size_bytes: -1});
  }));
  assert.equal((await store.loadTeamFile("team-1", file.fileId)).versionId, file.versionId);
  assert.equal((await database.select().from(fileVersions).where(eq(fileVersions.file_id, file.fileId))).length, 1);
});

test("file schema stores version metadata and team ownership in one place", async (t) => {
  const {database} = await fixture(t);
  const fileColumns = await database.all<{name: string}>(sql`PRAGMA table_info(files)`);
  const versionColumns = await database.all<{name: string}>(sql`PRAGMA table_info(file_versions)`);
  for (const name of ["content_type", "size_bytes", "storage_path"]) {
    assert.ok(!fileColumns.some((column) => column.name === name));
    assert.ok(versionColumns.some((column) => column.name === name));
  }
  assert.ok(!versionColumns.some((column) => column.name === "team_id"));
});
