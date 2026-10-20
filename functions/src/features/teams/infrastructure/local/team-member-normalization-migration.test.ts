import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test from "node:test";
import {connectRuntimeDatabase, type RuntimeDatabase} from "../../../../db/database.js";
import {teamMembers, userProfiles} from "../../../../db/schema.js";

const previousTables = [
  "CREATE TABLE teams (id TEXT PRIMARY KEY)",
  `CREATE TABLE team_members (team_id TEXT NOT NULL, uid TEXT NOT NULL,
    email TEXT NOT NULL, display_name TEXT NOT NULL, role TEXT NOT NULL,
    created_at TEXT NOT NULL, updated_at TEXT NOT NULL, PRIMARY KEY (team_id, uid),
    FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE)`,
  "INSERT INTO teams VALUES ('team-1'), ('team-2')",
  `INSERT INTO team_members VALUES
    ('team-1', 'user-1', 'old@example.org', 'Alter Name', 'owner', '2026-01-01', '2026-01-02'),
    ('team-2', 'user-1', 'new@example.org', 'Neuer Name', 'member', '2026-02-01', '2026-02-02'),
    ('team-2', 'user-2', 'second@example.org', 'Zweiter', 'owner', '2026-03-02', '2026-04-01'),
    ('team-1', 'user-2', 'first@example.org', 'Erster', 'member', '2026-03-01', '2026-04-01')`,
];

const expectedProfiles = [
  {uid: "user-1", email: "new@example.org", display_name: "Neuer Name", created_at: "2026-01-01", updated_at: "2026-02-02"},
  {uid: "user-2", email: "first@example.org", display_name: "Erster", created_at: "2026-03-01", updated_at: "2026-04-01"},
];

const expectedMemberships = [
  ["team-1", "user-1", "owner", "2026-01-01", "2026-01-02"],
  ["team-2", "user-1", "member", "2026-02-01", "2026-02-02"],
  ["team-1", "user-2", "member", "2026-03-01", "2026-04-01"],
  ["team-2", "user-2", "owner", "2026-03-02", "2026-04-01"],
];

async function migrateMembers(database: RuntimeDatabase) {
  const migration = await readFile(resolve(__dirname, "../../../../../drizzle/0011_normalize_team_members.sql"), "utf8");
  await database.transaction(async (tx) => {
    for (const statement of migration.split("--> statement-breakpoint")) await tx.run(sql.raw(statement.trim()));
  });
}

test("normalization consolidates whole profiles deterministically and preserves membership roles and dates", async (t) => {
  const database = connectRuntimeDatabase(":memory:");
  t.after(() => database.$client.close());
  await database.run(sql`PRAGMA foreign_keys = ON`);
  for (const statement of previousTables) await database.run(sql.raw(statement));
  await migrateMembers(database);
  const profiles = await database.select({
    uid: userProfiles.uid, email: userProfiles.email, display_name: userProfiles.display_name,
    created_at: userProfiles.created_at, updated_at: userProfiles.updated_at,
  }).from(userProfiles).orderBy(userProfiles.uid);
  assert.deepEqual(profiles, expectedProfiles);
  const members = await database.select().from(teamMembers).orderBy(teamMembers.uid, teamMembers.team_id);
  assert.deepEqual(members.map((row) => [row.team_id, row.uid, row.role, row.created_at, row.updated_at]), expectedMemberships);
  assert.deepEqual(await database.all(sql`PRAGMA foreign_key_check`), []);
});
