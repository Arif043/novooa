import {eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test from "node:test";
import {connectRuntimeDatabase} from "../../../../db/database.js";
import {files, fileVersions} from "../../../../db/schema.js";

const previousTables = [
  "CREATE TABLE teams (id TEXT PRIMARY KEY)",
  `CREATE TABLE files (id TEXT PRIMARY KEY, team_id TEXT NOT NULL, owner_uid TEXT NOT NULL,
    display_name TEXT NOT NULL, folder_id TEXT, current_version_id TEXT,
    content_type TEXT NOT NULL, size_bytes INTEGER NOT NULL, storage_path TEXT NOT NULL,
    created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
    FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE)`,
  `CREATE TABLE file_versions (id TEXT PRIMARY KEY, team_id TEXT NOT NULL, file_id TEXT NOT NULL,
    created_by_uid TEXT NOT NULL, display_name TEXT NOT NULL, storage_path TEXT NOT NULL,
    content_type TEXT NOT NULL, size_bytes INTEGER NOT NULL, created_at TEXT NOT NULL,
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE)`,
  "INSERT INTO teams VALUES ('team-1')",
  `INSERT INTO files VALUES ('file-1', 'team-1', 'user-1', 'file.txt', NULL, 'version-2',
    'text/plain', 2, 'latest', '2026-01-01', '2026-01-02')`,
  `INSERT INTO file_versions VALUES
    ('version-1', 'team-1', 'file-1', 'user-1', 'file.txt', 'older', 'text/plain', 1, '2026-01-01'),
    ('version-2', 'team-1', 'file-1', 'user-1', 'file.txt', 'latest', 'text/plain', 2, '2026-01-02')`,
];

test("normalization migration preserves files and versions with foreign keys enabled", async (t) => {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`PRAGMA foreign_keys = ON`);
  for (const statement of previousTables) await database.run(sql.raw(statement));
  const migration = await readFile(resolve(__dirname, "../../../../../drizzle/0009_normalize_file_versions.sql"), "utf8");
  await database.transaction(async (tx) => {
    for (const statement of migration.split("--> statement-breakpoint")) await tx.run(sql.raw(statement.trim()));
  });
  const file = await database.select().from(files).where(eq(files.id, "file-1")).get();
  assert.equal(file?.current_version_id, "version-2");
  const versions = await database.select().from(fileVersions).orderBy(fileVersions.id);
  assert.deepEqual(versions.map((row) => [row.id, row.size_bytes, row.storage_path]),
    [["version-1", 1, "older"], ["version-2", 2, "latest"]]);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_keys`), [{foreign_keys: 1}]);
});
