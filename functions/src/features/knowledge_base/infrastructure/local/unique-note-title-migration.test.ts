import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test from "node:test";
import {connectRuntimeDatabase} from "../../../../db/database.js";

test("the migration renames existing duplicates and then enforces unique titles", async (t) => {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`CREATE TABLE knowledge_notes (id TEXT PRIMARY KEY, team_id TEXT NOT NULL,
    knowledge_base_id TEXT NOT NULL, title TEXT NOT NULL, created_at TEXT NOT NULL)`);
  await database.run(sql`INSERT INTO knowledge_notes VALUES
    ('a', 'team-1', 'default', 'Fristen', '2026-01-01'),
    ('b', 'team-1', 'default', 'fristen', '2026-01-02'),
    ('c', 'team-2', 'default', 'Fristen', '2026-01-03')`);
  const migration = await readFile(resolve(__dirname, "../../../../../drizzle/0032_unique_note_titles.sql"), "utf8");

  for (const statement of migration.split("--> statement-breakpoint")) await database.run(sql.raw(statement));

  assert.deepEqual(await database.all(sql`SELECT id, title FROM knowledge_notes ORDER BY id`), [
    {id: "a", title: "Fristen"}, {id: "b", title: "fristen (b)"}, {id: "c", title: "Fristen"},
  ]);
  await assert.rejects(database.run(sql`INSERT INTO knowledge_notes VALUES ('d', 'team-1', 'default', 'FRISTEN', '2026-01-04')`));
});
