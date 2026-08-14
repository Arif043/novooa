import assert from "node:assert/strict";
import test from "node:test";
import {SQLiteTeamContextStore} from "./sqlite-team-context-store.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";

test("returns the local team for a member", async () => {
  const store = new SQLiteTeamContextStore(databaseWith({team_id: "team-1"}));

  const teamId = await store.currentTeamIdForUid("user-1");

  assert.equal(teamId, "team-1");
});

test("rejects a local user without a team", async () => {
  const store = new SQLiteTeamContextStore(databaseWith(null));

  await assert.rejects(() => store.currentTeamIdForUid("user-1"));
});

function databaseWith(row: SqlRow | null): LocalSqlDatabase {
  return {
    get: async <T extends SqlRow>() => row as T | null,
    all: async <T extends SqlRow>() => [] as T[],
    run: async () => undefined,
    transaction: async <T>(operation: () => Promise<T>) => operation(),
  };
}
