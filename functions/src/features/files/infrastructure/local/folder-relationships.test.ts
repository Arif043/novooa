import {eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {mkdtemp, readdir, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {fileFolders, files, fileVersions, teams} from "../../../../db/schema.js";
import {LocalTeamFileStore} from "./local-team-file-store.js";
import {SQLiteFileSettingsStore} from "./sqlite-file-settings-store.js";

async function fixture(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(teams).values({id: "team-2", name: "Zweites Team", owner_uid: "u"});
  await database.insert(fileFolders).values([
    {id: "root-1", root_team_id: "team-1", owner_uid: "u", name: "Wurzel"},
    {id: "root-2", root_team_id: "team-2", owner_uid: "u", name: "Andere Wurzel"},
    {id: "child", owner_uid: "u", name: "Kind", parent_folder_id: "root-1"},
  ]);
  return database;
}

test("folder references enforce team ownership on inserts and moves", async (t) => {
  const database = await fixture(t);
  await assert.rejects(database.insert(fileFolders).values({id: "invalid", root_team_id: "team-1",
    owner_uid: "u", name: "Ungültig", parent_folder_id: "root-2"}));
  await assert.rejects(database.update(fileFolders).set({parent_folder_id: "root-2"}).where(eq(fileFolders.id, "child")));
  await assert.rejects(database.update(fileFolders).set({parent_folder_id: "missing"}).where(eq(fileFolders.id, "child")));
  await database.update(fileFolders).set({parent_folder_id: null, root_team_id: "team-1"}).where(eq(fileFolders.id, "child"));
  assert.equal((await database.select().from(fileFolders).where(eq(fileFolders.id, "child")))[0].parent_folder_id, null);
});

test("files enforce exclusive root placement and team-preserving folder moves", async (t) => {
  const database = await fixture(t);
  const file = {id: "file-1", root_team_id: "team-1", owner_uid: "u", display_name: "Datei"};
  for (const folder_id of ["missing", "root-2"]) {
    await assert.rejects(database.insert(files).values({...file, folder_id}));
  }
  await database.insert(files).values(file);
  await database.update(files).set({folder_id: "child", root_team_id: null}).where(eq(files.id, file.id));
  await assert.rejects(database.update(files).set({folder_id: "root-2"}).where(eq(files.id, file.id)));
  assert.equal((await database.select().from(files))[0].folder_id, "child");
});

test("self references, descendant moves and multi-row cycle insertion are rejected", async (t) => {
  const database = await fixture(t);
  await assert.rejects(database.insert(fileFolders).values({id: "self", owner_uid: "u", name: "Selbst", parent_folder_id: "self"}));
  await database.insert(fileFolders).values({id: "grandchild", owner_uid: "u", name: "Enkel", parent_folder_id: "child"});
  await assert.rejects(database.update(fileFolders).set({parent_folder_id: "grandchild"}).where(eq(fileFolders.id, "root-1")));
  await assert.rejects(database.insert(fileFolders).values([
    {id: "cycle-a", owner_uid: "u", name: "A", parent_folder_id: "cycle-b"},
    {id: "cycle-b", owner_uid: "u", name: "B", parent_folder_id: "cycle-a"},
  ]));
  assert.equal((await database.select().from(fileFolders).where(eq(fileFolders.id, "root-1")))[0].parent_folder_id, null);
});

test("a populated folder tree cannot be deleted; empty trees cascade", async (t) => {
  const database = await fixture(t);
  await database.insert(files).values({id: "file-1", owner_uid: "u", display_name: "Datei", folder_id: "child"});
  await assert.rejects(database.delete(fileFolders).where(eq(fileFolders.id, "root-1")));
  assert.equal((await database.select().from(fileFolders)).length, 3);
  assert.equal((await database.select().from(files)).length, 1);
  await database.delete(files).where(eq(files.id, "file-1"));
  await database.delete(fileFolders).where(eq(fileFolders.id, "root-1"));
  assert.deepEqual((await database.select().from(fileFolders)).map((row) => row.id), ["root-2"]);
});

test("renaming an ID cannot close a cycle with deferred foreign keys", async (t) => {
  const database = await fixture(t);
  await assert.rejects(database.transaction(async (tx) => {
    await tx.run(sql`PRAGMA defer_foreign_keys = ON`);
    await tx.insert(fileFolders).values({id: "pending-a", owner_uid: "u", name: "A", parent_folder_id: "pending-b"});
    await tx.insert(fileFolders).values({id: "pending-c", owner_uid: "u", name: "C", parent_folder_id: "pending-a"});
    await tx.update(fileFolders).set({id: "pending-b"}).where(eq(fileFolders.id, "pending-c"));
  }));
  assert.equal((await database.select().from(fileFolders)).length, 3);
});

test("team deletion still cascades folders, files and versions together", async (t) => {
  const database = await fixture(t);
  await database.insert(files).values({id: "file-1", owner_uid: "u", display_name: "Datei", folder_id: "child"});
  await database.insert(fileVersions).values({id: "version-1", file_id: "file-1", created_by_uid: "u", display_name: "Datei", storage_path: "blob"});
  await database.update(files).set({current_version_id: "version-1"}).where(eq(files.id, "file-1"));
  await database.delete(teams).where(eq(teams.id, "team-1"));
  assert.deepEqual(await database.select().from(files), []);
  assert.deepEqual(await database.select().from(fileVersions), []);
  assert.deepEqual((await database.select().from(fileFolders)).map((row) => row.id), ["root-2"]);
});

test("file store rejects foreign folders before writing and cleans blobs after metadata failure", async (t) => {
  const database = await fixture(t);
  const directory = await mkdtemp(join(tmpdir(), "novooa-folder-test-"));
  t.after(() => rm(directory, {recursive: true, force: true}));
  const store = new LocalTeamFileStore(database, directory, new SQLiteFileSettingsStore(database));
  const input = {teamId: "team-1", fileName: "Datei", contentType: "text/plain", content: "Inhalt", targetFileId: null};
  await assert.rejects(store.writeTeamFile({...input, folderId: "root-2"}));
  assert.deepEqual(await readdir(directory), []);
  await database.run(sql`CREATE TRIGGER reject_file_version BEFORE INSERT ON file_versions
    BEGIN SELECT RAISE(ABORT, 'Version abgelehnt'); END`);
  await assert.rejects(store.writeTeamFile({...input, folderId: "child"}));
  const entries = await readdir(directory, {recursive: true, withFileTypes: true});
  assert.ok(entries.every((entry) => !entry.isFile()));
  assert.deepEqual(await database.select().from(files), []);
});
