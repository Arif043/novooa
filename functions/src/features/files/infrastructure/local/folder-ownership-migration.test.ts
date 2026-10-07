import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test, {type TestContext} from "node:test";
import {connectRuntimeDatabase, type RuntimeDatabase} from "../../../../db/database.js";

const migrationDirectory = resolve(__dirname, "../../../../../drizzle");

async function applyMigration(database: RuntimeDatabase, tag: string) {
  const migration = await readFile(resolve(migrationDirectory, `${tag}.sql`), "utf8");
  await database.transaction(async (tx) => {
    for (const statement of migration.split("--> statement-breakpoint")) await tx.run(sql.raw(statement.trim()));
  });
}

async function previousDatabase(t: TestContext) {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`PRAGMA foreign_keys = ON`);
  const journal = JSON.parse(await readFile(resolve(migrationDirectory, "meta/_journal.json"), "utf8")) as {
    entries: Array<{idx: number; tag: string}>;
  };
  for (const entry of journal.entries.filter((entry) => entry.idx <= 17)) await applyMigration(database, entry.tag);
  await seed(database);
  return database;
}

async function seed(database: RuntimeDatabase) {
  await database.run(sql`INSERT INTO teams (id, name, owner_uid) VALUES ('team-1', 'Erstes', 'u'), ('team-2', 'Zweites', 'u')`);
  await database.run(sql`INSERT INTO file_folders (id, team_id, owner_uid, name, parent_folder_id) VALUES
    ('root-1', 'team-1', 'u', 'Wurzel', NULL), ('root-2', 'team-2', 'u', 'Andere Wurzel', NULL),
    ('child', 'team-1', 'u', 'Kind', 'root-1'), ('grandchild', 'team-1', 'u', 'Enkel', 'child')`);
  await database.run(sql`INSERT INTO files (id, root_team_id, owner_uid, display_name, folder_id) VALUES
    ('root-file', 'team-1', 'u', 'Wurzeldatei', NULL), ('assigned', NULL, 'u', 'Ordnerdatei', 'grandchild')`);
  await database.run(sql`INSERT INTO file_versions (rowid, id, file_id, created_by_uid, display_name, storage_path, size_bytes) VALUES
    (13, 'old', 'assigned', 'u', 'Alter Name', 'blob-1', 1), (42, 'current', 'assigned', 'u', 'Neuer Name', 'blob-2', 2)`);
  await database.run(sql`UPDATE files SET current_version_id = 'current' WHERE id = 'assigned'`);
}

async function stateOf(database: RuntimeDatabase) {
  return {
    folders: await database.all(sql`SELECT * FROM file_folders ORDER BY id`),
    files: await database.all(sql`SELECT * FROM files ORDER BY id`),
    versions: await database.all(sql`SELECT rowid, * FROM file_versions ORDER BY rowid`),
  };
}

test("folder ownership migration preserves hierarchy, files, metadata and version order", async (t) => {
  const database = await previousDatabase(t);
  const previous = await stateOf(database);
  const previousFolders = await database.all(sql`SELECT id, owner_uid, name, parent_folder_id, created_at, updated_at FROM file_folders ORDER BY id`);
  await applyMigration(database, "0018_normalize_folder_ownership");
  const migrated = await stateOf(database);
  assert.deepEqual(migrated.files, previous.files);
  assert.deepEqual(migrated.versions, previous.versions);
  assert.deepEqual(await database.all(sql`SELECT id, owner_uid, name, parent_folder_id, created_at, updated_at FROM file_folders ORDER BY id`), previousFolders);
  assert.deepEqual(await database.all(sql`SELECT id, root_team_id FROM file_folders ORDER BY id`), [
    {id: "child", root_team_id: null}, {id: "grandchild", root_team_id: null},
    {id: "root-1", root_team_id: "team-1"}, {id: "root-2", root_team_id: "team-2"},
  ]);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_keys`), [{foreign_keys: 1}]);
  await database.run(sql`DELETE FROM teams WHERE id = 'team-1'`);
  assert.deepEqual((await stateOf(database)).files, []);
  assert.deepEqual((await stateOf(database)).versions, []);
});

for (const parent of ["root-2", "missing", "grandchild"]) {
  test(`folder ownership migration rejects invalid ancestry and rolls back: ${parent}`, async (t) => {
    const database = await previousDatabase(t);
    await database.run(sql`PRAGMA foreign_keys = OFF`);
    await database.run(sql`DROP TRIGGER file_folders_no_cycle_update`);
    await database.run(sql`UPDATE file_folders SET parent_folder_id = ${parent} WHERE id = 'child'`);
    await database.run(sql`PRAGMA foreign_keys = ON`);
    const previous = await stateOf(database);
    await assert.rejects(applyMigration(database, "0018_normalize_folder_ownership"));
    assert.deepEqual(await stateOf(database), previous);
    assert.deepEqual(await database.all(sql`SELECT name FROM sqlite_master WHERE name = '__folder_ownership_guard'`), []);
  });
}
