import {eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {fileFolders, files, fileVersions, teams} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {fileResourceRoutes} from "./local-file-resource-routes.js";
import {fileLocation, fileTeamId} from "./local-file-team.js";
import {LocalTeamFileStore} from "./local-team-file-store.js";
import {SQLiteFileSettingsStore} from "./sqlite-file-settings-store.js";

async function fixture(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(teams).values({id: "team-2", name: "Andere", owner_uid: "u"});
  await database.insert(fileFolders).values([
    {id: "folder-1", team_id: "team-1", owner_uid: "u", name: "Ordner"},
    {id: "folder-2", team_id: "team-2", owner_uid: "u", name: "Anderer Ordner"},
  ]);
  return database;
}

test("files have exactly one ownership source and derive the team from their folder", async (t) => {
  const database = await fixture(t);
  const base = {owner_uid: "u", display_name: "Datei"};
  await assert.rejects(database.insert(files).values({id: "missing", ...base}));
  await assert.rejects(database.insert(files).values({id: "both", ...base, root_team_id: "team-1", folder_id: "folder-1"}));
  await assert.rejects(database.insert(files).values({id: "orphan", ...base, root_team_id: "missing"}));
  await assert.rejects(database.insert(files).values({id: "missing-folder", ...base, folder_id: "missing"}));
  await database.insert(files).values([
    {id: "root", ...base, ...fileLocation("team-1", null)},
    {id: "assigned", ...base, ...fileLocation("team-1", "folder-1")},
  ]);
  const rows = await database.select({id: files.id, root: files.root_team_id, team: fileTeamId}).from(files).orderBy(files.id);
  assert.deepEqual(rows, [{id: "assigned", root: null, team: "team-1"}, {id: "root", root: "team-1", team: "team-1"}]);
  const columns = await database.all<{name: string}>(sql`PRAGMA table_info(files)`);
  assert.ok(!columns.some((column) => column.name === "team_id"));
});

test("same-team root and folder moves succeed, cross-team moves and folder reassignment fail", async (t) => {
  const database = await fixture(t);
  await database.insert(files).values({id: "file", owner_uid: "u", display_name: "Datei", ...fileLocation("team-1", null)});
  await database.update(files).set(fileLocation("team-1", "folder-1")).where(eq(files.id, "file"));
  await assert.rejects(database.update(files).set(fileLocation("team-2", "folder-2")).where(eq(files.id, "file")));
  await assert.rejects(database.update(fileFolders).set({team_id: "team-2"}).where(eq(fileFolders.id, "folder-1")));
  await database.update(files).set(fileLocation("team-1", null)).where(eq(files.id, "file"));
  await assert.rejects(database.update(files).set(fileLocation("team-2", null)).where(eq(files.id, "file")));
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
});

test("deleting a team removes root and assigned files and their versions, preserving other teams", async (t) => {
  const database = await fixture(t);
  await database.insert(files).values([
    {id: "root", owner_uid: "u", display_name: "Wurzel", ...fileLocation("team-1", null)},
    {id: "assigned", owner_uid: "u", display_name: "Ordner", ...fileLocation("team-1", "folder-1")},
    {id: "other", owner_uid: "u", display_name: "Andere", ...fileLocation("team-2", "folder-2")},
  ]);
  for (const id of ["root", "assigned", "other"]) {
    await database.insert(fileVersions).values({id: `v-${id}`, file_id: id, created_by_uid: "u", display_name: id, storage_path: id});
    await database.update(files).set({current_version_id: `v-${id}`}).where(eq(files.id, id));
  }
  await database.delete(teams).where(eq(teams.id, "team-1"));
  assert.deepEqual((await database.select().from(files)).map((row) => row.id), ["other"]);
  assert.deepEqual((await database.select().from(fileVersions)).map((row) => row.id), ["v-other"]);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
});

test("folder files retain API ownership, version access and deletion isolation", async (t) => {
  const database = await fixture(t);
  const directory = await mkdtemp(join(tmpdir(), "novooa-file-ownership-"));
  t.after(() => rm(directory, {recursive: true, force: true}));
  const store = new LocalTeamFileStore(database, directory, new SQLiteFileSettingsStore(database));
  const options = {database, fileStore: store, notifier: {publish: () => undefined}};
  const routes = testingRoutes(fileResourceRoutes, options);
  const otherRoutes = testingRoutes(fileResourceRoutes, options, {teamId: "team-2"});
  const file = await store.writeTeamFile({teamId: "team-1", fileName: "Datei", content: "Inhalt", contentType: "text/plain",
    folderId: "folder-1", targetFileId: null});
  const response = await routes.handle({url: "/v1/files", body: {}});
  const listed = (response?.body as {items: Array<{teamId: string; folderId: string}>}).items;
  assert.equal(listed[0].teamId, "team-1");
  assert.equal(listed[0].folderId, "folder-1");
  assert.deepEqual((await otherRoutes.handle({url: "/v1/files", body: {}}))?.body, {items: []});
  await assert.rejects(store.readTeamFileContent("team-2", file.fileId, file.versionId));
  assert.equal(await store.deleteTeamFile("team-2", file.fileId), false);
  assert.equal((await store.loadTeamFile("team-1", file.fileId)).versionId, file.versionId);
  assert.equal(await store.deleteTeamFile("team-1", file.fileId), true);
});
