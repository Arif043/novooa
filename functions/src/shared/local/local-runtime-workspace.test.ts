import assert from "node:assert/strict";
import test from "node:test";
import {SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";
import {ensureLocalRuntimeWorkspace} from "./local-runtime-workspace.js";

test("creates the initial local workspace only once", async () => {
  const database = new SqliteLocalSqlDatabase(":memory:");
  try {
    await createWorkspaceTables(database);
    const workspace = {
      teamId: "local-team", teamName: "Lokaler Arbeitsbereich", userId: "local-user",
    };

    await ensureLocalRuntimeWorkspace(database, workspace);
    await ensureLocalRuntimeWorkspace(database, workspace);

    assert.deepEqual(await database.get<{name: string; owner_uid: string}>(
      "SELECT name, owner_uid FROM teams WHERE id = ?", ["local-team"],
    ), {name: "Lokaler Arbeitsbereich", owner_uid: "local-user"});
    assert.deepEqual(await database.get<{role: string}>(
      "SELECT role FROM team_members WHERE team_id = ? AND uid = ?",
      ["local-team", "local-user"],
    ), {role: "owner"});
  } finally {
    database.close();
  }
});

async function createWorkspaceTables(database: SqliteLocalSqlDatabase): Promise<void> {
  await database.run("CREATE TABLE teams (id TEXT PRIMARY KEY, name TEXT, owner_uid TEXT)");
  await database.run(`CREATE TABLE team_members (
    team_id TEXT, uid TEXT, display_name TEXT, role TEXT,
    PRIMARY KEY (team_id, uid)
  )`);
}
