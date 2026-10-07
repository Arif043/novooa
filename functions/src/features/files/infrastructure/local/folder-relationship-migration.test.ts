import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test, {type TestContext} from "node:test";
import {connectRuntimeDatabase, type RuntimeDatabase} from "../../../../db/database.js";

const previousStatements = [
  "CREATE TABLE teams (id TEXT PRIMARY KEY)",
  `CREATE TABLE file_folders (id TEXT PRIMARY KEY, team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    owner_uid TEXT NOT NULL, name TEXT NOT NULL, parent_folder_id TEXT REFERENCES file_folders(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL, updated_at TEXT NOT NULL)`,
  `CREATE TABLE files (id TEXT PRIMARY KEY, team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    owner_uid TEXT NOT NULL, display_name TEXT NOT NULL, folder_id TEXT, current_version_id TEXT,
    created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
    FOREIGN KEY(id, current_version_id) REFERENCES file_versions(file_id, id))`,
  `CREATE TABLE file_versions (id TEXT PRIMARY KEY, file_id TEXT NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    created_by_uid TEXT NOT NULL, display_name TEXT NOT NULL, storage_path TEXT NOT NULL,
    content_type TEXT NOT NULL, size_bytes INTEGER NOT NULL, created_at TEXT NOT NULL, UNIQUE(file_id, id))`,
  "INSERT INTO teams VALUES ('team-1'), ('team-2')",
  `INSERT INTO file_folders VALUES
    ('root-1', 'team-1', 'u', 'Wurzel', NULL, '2026-01-01', '2026-01-02'),
    ('root-2', 'team-2', 'u', 'Andere Wurzel', NULL, '2026-01-01', '2026-01-02'),
    ('child', 'team-1', 'u', 'Kind', 'root-1', '2026-01-03', '2026-01-04')`,
  "INSERT INTO files VALUES ('file-1', 'team-1', 'u', 'Datei', 'child', NULL, '2026-01-01', '2026-01-02')",
  `INSERT INTO file_versions(rowid, id, file_id, created_by_uid, display_name, storage_path, content_type, size_bytes, created_at)
    VALUES (13, 'version-1', 'file-1', 'u', 'Alter Name', 'blob-1', 'text/plain', 1, '2026-01-01'),
      (42, 'version-2', 'file-1', 'u', 'Neuer Name', 'blob-2', 'text/plain', 2, '2026-01-01')`,
  "UPDATE files SET current_version_id = 'version-2'",
];

async function previousDatabase(t: TestContext) {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`PRAGMA foreign_keys = ON`);
  for (const statement of previousStatements) await database.run(sql.raw(statement));
  return database;
}

async function migrateFolders(database: RuntimeDatabase) {
  const migration = await readFile(resolve(__dirname, "../../../../../drizzle/0016_secure_folder_relationships.sql"), "utf8");
  await database.transaction(async (tx) => {
    for (const statement of migration.split("--> statement-breakpoint")) await tx.run(sql.raw(statement.trim()));
  });
}

async function fileState(database: RuntimeDatabase) {
  return {
    folders: await database.all(sql`SELECT * FROM file_folders ORDER BY id`),
    files: await database.all(sql`SELECT * FROM files ORDER BY id`),
    versions: await database.all(sql`SELECT rowid, * FROM file_versions ORDER BY rowid`),
  };
}

test("migration preserves folder tree, current version, all metadata and version row order", async (t) => {
  const database = await previousDatabase(t);
  const originalState = await fileState(database);
  await migrateFolders(database);
  assert.deepEqual(await fileState(database), originalState);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
  await assert.rejects(database.run(sql`UPDATE files SET folder_id = 'root-2'`));
  await assert.rejects(database.run(sql`UPDATE file_folders SET parent_folder_id = 'child' WHERE id = 'root-1'`));
});

const invalidChanges = [
  "UPDATE file_folders SET parent_folder_id = 'root-2' WHERE id = 'child'",
  "UPDATE file_folders SET parent_folder_id = 'child' WHERE id = 'root-1'",
  "UPDATE files SET folder_id = 'root-2'",
  "UPDATE files SET folder_id = 'missing'",
];

for (const invalidChange of invalidChanges) {
  test(`migration rejects ${invalidChange} without losing files or versions`, async (t) => {
    const database = await previousDatabase(t);
    await database.run(sql.raw(invalidChange));
    const originalState = await fileState(database);
    await assert.rejects(migrateFolders(database));
    assert.deepEqual(await fileState(database), originalState);
    assert.deepEqual(await database.all(sql`SELECT name FROM sqlite_master WHERE name = '__folder_relationship_guard'`), []);
  });
}
