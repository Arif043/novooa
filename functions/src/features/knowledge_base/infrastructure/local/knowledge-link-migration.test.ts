import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test, {type TestContext} from "node:test";
import {connectRuntimeDatabase} from "../../../../db/database.js";

async function previousDatabase(t: TestContext) {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`PRAGMA foreign_keys = ON`);
  await database.run(sql`CREATE TABLE teams (id TEXT PRIMARY KEY)`);
  await database.run(sql`CREATE TABLE knowledge_notes (id TEXT PRIMARY KEY,
    team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE, knowledge_base_id TEXT NOT NULL,
    title TEXT NOT NULL, path TEXT NOT NULL, type TEXT NOT NULL, content TEXT NOT NULL,
    outgoing_links_json TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)`);
  await database.run(sql`CREATE INDEX idx_notes_team_base ON knowledge_notes(team_id, knowledge_base_id)`);
  await database.run(sql`INSERT INTO teams VALUES ('team-1')`);
  await database.run(sql`INSERT INTO knowledge_notes VALUES
    ('source', 'team-1', 'default', 'Index', 'index.md', 'markdown', '[[Ziel]]', 'ungültige Projektion', '2026-01-01', '2026-01-02')`);
  return database;
}

test("link migration removes only the derived projection and preserves all authoritative note fields", async (t) => {
  const database = await previousDatabase(t);
  const previous = await database.all(sql`SELECT id, team_id, knowledge_base_id, title, path, type, content, created_at, updated_at FROM knowledge_notes`);
  const migration = await readFile(resolve(__dirname, "../../../../../drizzle/0019_normalize_knowledge_links.sql"), "utf8");
  await database.transaction(async (tx) => { await tx.run(sql.raw(migration)); });
  assert.deepEqual(await database.all(sql`SELECT * FROM knowledge_notes`), previous);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
  assert.deepEqual(await database.all(sql`SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_notes_team_base'`), [{name: "idx_notes_team_base"}]);
});
