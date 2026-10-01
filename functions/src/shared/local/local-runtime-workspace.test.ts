import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {connectRuntimeDatabase, RuntimeDatabase} from "../../db/database.js";
import {ensureLocalRuntimeWorkspace} from "./local-runtime-workspace.js";

test("creates the initial local workspace only once", async () => {
  const database = connectRuntimeDatabase(":memory:");
  try {
    await createWorkspaceTables(database);
    const workspace = {
      teamId: "local-team", teamName: "Lokaler Arbeitsbereich", userId: "local-user",
    };

    await ensureLocalRuntimeWorkspace(database, workspace);
    await ensureLocalRuntimeWorkspace(database, workspace);

    assert.deepEqual(await database.get <{name: string; owner_uid: string}>(sql`SELECT name, owner_uid FROM teams WHERE id = ${"local-team"}`), {name: "Lokaler Arbeitsbereich", owner_uid: "local-user"});
    assert.deepEqual(await database.get <{role: string}>(sql`SELECT role FROM team_members WHERE team_id = ${"local-team"} AND uid = ${"local-user"}`), {role: "owner"});
  } finally {
    database.$client.close();
  }
});

async function createWorkspaceTables(database: RuntimeDatabase): Promise<void> {
  await database.run(sql`CREATE TABLE teams (id TEXT PRIMARY KEY, name TEXT, owner_uid TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT DEFAULT CURRENT_TIMESTAMP)`);
  await database.run(sql`CREATE TABLE team_members (
    team_id TEXT, uid TEXT, display_name TEXT, role TEXT, email TEXT NOT NULL DEFAULT '',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP, updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (team_id, uid)
  )`);
}
