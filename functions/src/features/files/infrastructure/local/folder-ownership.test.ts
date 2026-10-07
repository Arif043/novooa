import {eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {fileFolders, files, teams} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {fileResourceRoutes} from "./local-file-resource-routes.js";
import {fileLocation, fileTeamId} from "./sqlite-file-team.js";
import {folderExists} from "./sqlite-folder-reference.js";
import {folderLocation, folderTeamId} from "./sqlite-folder-team.js";
import {SQLiteFolderAncestry} from "./sqlite-folder-ancestry.js";

async function fixture(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(teams).values({id: "team-2", name: "Andere", owner_uid: "u"});
  const base = {owner_uid: "u", name: "Ordner"};
  for (const [id, team, parent] of [
    ["root-1", "team-1", null], ["other-root-1", "team-1", null], ["root-2", "team-2", null],
    ["child", "team-1", "root-1"], ["grandchild", "team-1", "child"],
  ] as const) {
    await database.insert(fileFolders).values({id, ...base, ...folderLocation(team, parent)});
  }
  return database;
}

test("folder and file teams are resolved through every ancestor without storing child teams", async (t) => {
  const database = await fixture(t);
  const folders = await database.select({id: fileFolders.id, root: fileFolders.root_team_id, team: folderTeamId})
    .from(fileFolders).where(eq(folderTeamId, "team-1")).orderBy(fileFolders.id);
  assert.deepEqual(folders.map((row) => [row.id, row.root, row.team]), [
    ["child", null, "team-1"], ["grandchild", null, "team-1"],
    ["other-root-1", "team-1", "team-1"], ["root-1", "team-1", "team-1"],
  ]);
  await database.insert(files).values({id: "file", owner_uid: "u", display_name: "Datei", ...fileLocation("team-1", "grandchild")});
  assert.deepEqual(await database.select({team: fileTeamId}).from(files), [{team: "team-1"}]);
  await assert.rejects(database.update(files).set(fileLocation("team-2", "root-2")).where(eq(files.id, "file")));
  assert.equal(await folderExists(database, "team-2", "grandchild"), false);
  const ancestry = new SQLiteFolderAncestry(database);
  assert.deepEqual(await ancestry.chainOf("team-1", "grandchild"), ["grandchild", "child", "root-1"]);
  assert.equal((await ancestry.parentsOf("team-2")).has("grandchild"), false);
  const columns = await database.all<{name: string}>(sql`PRAGMA table_info(file_folders)`);
  assert.ok(!columns.some((column) => column.name === "team_id"));
  await database.delete(teams).where(eq(teams.id, "team-1"));
  assert.deepEqual(await database.select().from(files), []);
  assert.deepEqual((await database.select().from(fileFolders)).map((folder) => folder.id), ["root-2"]);
});

test("folders require exactly one location and cannot change their inherited team", async (t) => {
  const database = await fixture(t);
  const base = {owner_uid: "u", name: "Ordner"};
  await assert.rejects(database.insert(fileFolders).values({id: "neither", ...base}));
  await assert.rejects(database.insert(fileFolders).values({id: "both", ...base, root_team_id: "team-1", parent_folder_id: "root-1"}));
  await assert.rejects(database.insert(fileFolders).values({id: "missing", ...base, parent_folder_id: "missing"}));
  await assert.rejects(database.update(fileFolders).set(folderLocation("team-2", "root-2")).where(eq(fileFolders.id, "child")));
  await assert.rejects(database.update(fileFolders).set(folderLocation("team-2", null)).where(eq(fileFolders.id, "root-1")));
  await database.update(fileFolders).set(folderLocation("team-1", "other-root-1")).where(eq(fileFolders.id, "child"));
  await database.update(fileFolders).set(folderLocation("team-1", null)).where(eq(fileFolders.id, "child"));
  assert.equal(await folderExists(database, "team-1", "grandchild"), true);
  await assert.rejects(database.update(fileFolders).set(folderLocation("team-1", "grandchild")).where(eq(fileFolders.id, "child")));
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
});

test("folder API returns derived team IDs and rejects foreign parents before creating rows", async (t) => {
  const database = await fixture(t);
  const options = {database, notifier: {publish: () => undefined}, fileStore: {
    writeTeamFile: async () => { throw new Error("Unerwarteter Datei-Schreibzugriff"); },
    readTeamFileContent: async () => { throw new Error("Unerwarteter Datei-Lesezugriff"); },
    deleteTeamFile: async () => false,
  }};
  const routes = testingRoutes(fileResourceRoutes, options);
  const listed = (await routes.handle({url: "/v1/folders", body: {}}))?.body as {items: Array<{id: string; teamId: string}>};
  assert.equal(listed.items.length, 4);
  assert.ok(listed.items.every((folder) => folder.teamId === "team-1"));
  const created = await routes.handle({method: "POST", url: "/v1/folders", body: {name: "Neuer Ordner", parentFolderId: "grandchild"}});
  assert.equal(created?.statusCode, 201);
  const folder = created?.body as {id: string; teamId: string};
  assert.equal(folder.teamId, "team-1");
  assert.equal((await database.select().from(fileFolders).where(eq(fileFolders.id, folder.id)).get())?.root_team_id, null);
  const rejected = await routes.handle({method: "POST", url: "/v1/folders", body: {name: "Fremd", parentFolderId: "root-2"}});
  assert.equal(rejected?.statusCode, 400);
  assert.equal((await database.select().from(fileFolders)).length, 6);
});
