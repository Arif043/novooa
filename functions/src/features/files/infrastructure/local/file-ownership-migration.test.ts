import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test, {type TestContext} from "node:test";
import {connectRuntimeDatabase, type RuntimeDatabase} from "../../../../db/database.js";

const previousStatements = [
  "CREATE TABLE teams (id TEXT PRIMARY KEY)",
  `CREATE TABLE file_folders (id TEXT PRIMARY KEY, team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    owner_uid TEXT NOT NULL, name TEXT NOT NULL, parent_folder_id TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)`,
  `CREATE TABLE files (id TEXT PRIMARY KEY, team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    owner_uid TEXT NOT NULL, display_name TEXT NOT NULL, folder_id TEXT, current_version_id TEXT,
    created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
    FOREIGN KEY(id, current_version_id) REFERENCES file_versions(file_id, id))`,
  `CREATE TABLE file_versions (id TEXT PRIMARY KEY, file_id TEXT NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    created_by_uid TEXT NOT NULL, display_name TEXT NOT NULL, storage_path TEXT NOT NULL,
    content_type TEXT NOT NULL, size_bytes INTEGER NOT NULL, created_at TEXT NOT NULL, UNIQUE(file_id, id))`,
  "INSERT INTO teams VALUES ('team-1'), ('team-2')",
  "INSERT INTO file_folders VALUES ('folder', 'team-1', 'u', 'Ordner', NULL, '2026-01-01', '2026-01-02')",
  `INSERT INTO files VALUES
    ('root', 'team-1', 'u', 'Wurzeldatei', NULL, NULL, '2026-01-01', '2026-01-02'),
    ('assigned', 'team-1', 'u', 'Ordnerdatei', 'folder', NULL, '2026-01-03', '2026-01-04')`,
  `INSERT INTO file_versions(rowid, id, file_id, created_by_uid, display_name, storage_path, content_type, size_bytes, created_at)
    VALUES (13, 'old', 'assigned', 'u', 'Alter Name', 'blob-1', 'text/plain', 1, '2026-01-01'),
      (42, 'current', 'assigned', 'u', 'Neuer Name', 'blob-2', 'text/plain', 2, '2026-01-01')`,
  "UPDATE files SET current_version_id = 'current' WHERE id = 'assigned'",
];

async function previousDatabase(t: TestContext) {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`PRAGMA foreign_keys = ON`);
  for (const statement of previousStatements) await database.run(sql.raw(statement));
  return database;
}

async function migrateOwnership(database: RuntimeDatabase) {
  const migration = await readFile(resolve(__dirname, "../../../../../drizzle/0017_normalize_file_ownership.sql"), "utf8");
  await database.transaction(async (tx) => {
    for (const statement of migration.split("--> statement-breakpoint")) await tx.run(sql.raw(statement.trim()));
  });
}

async function stateOf(database: RuntimeDatabase) {
  return {
    files: await database.all(sql`SELECT * FROM files ORDER BY id`),
    versions: await database.all(sql`SELECT rowid, * FROM file_versions ORDER BY rowid`),
  };
}

test("ownership migration derives folder ownership and preserves metadata, current version and version order", async (t) => {
  const database = await previousDatabase(t);
  const previous = await stateOf(database);
  const previousMetadata = await database.all(sql`SELECT id, owner_uid, display_name, folder_id, current_version_id, created_at, updated_at FROM files ORDER BY id`);
  await migrateOwnership(database);
  const migrated = await stateOf(database);
  assert.deepEqual(migrated.versions, previous.versions);
  const oldMetadata = await database.all(sql`SELECT id, owner_uid, display_name, folder_id, current_version_id, created_at, updated_at FROM files ORDER BY id`);
  assert.deepEqual(oldMetadata, previousMetadata);
  assert.deepEqual(await database.all(sql`SELECT id, root_team_id FROM files ORDER BY id`),
    [{id: "assigned", root_team_id: null}, {id: "root", root_team_id: "team-1"}]);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_keys`), [{foreign_keys: 1}]);
});

for (const change of ["UPDATE files SET team_id = 'team-2' WHERE id = 'assigned'",
  "UPDATE files SET folder_id = 'missing' WHERE id = 'assigned'"]) {
  test(`ownership migration rejects invalid placement and rolls back: ${change}`, async (t) => {
    const database = await previousDatabase(t);
    await database.run(sql.raw(change));
    const previous = await stateOf(database);
    await assert.rejects(migrateOwnership(database));
    assert.deepEqual(await stateOf(database), previous);
    assert.deepEqual(await database.all(sql`SELECT name FROM sqlite_master WHERE name = '__file_ownership_guard'`), []);
  });
}
