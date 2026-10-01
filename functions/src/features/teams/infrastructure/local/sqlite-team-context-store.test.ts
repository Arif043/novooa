import assert from "node:assert/strict";
import test from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {teamMembers} from "../../../../db/schema.js";
import {SQLiteTeamContextStore} from "./sqlite-team-context-store.js";

test("returns the local team for a member", async (t) => {
  const database = await runtimeTestDatabase(t);
  await database.insert(teamMembers).values({team_id: "team-1", uid: "user-1"});
  assert.equal(await new SQLiteTeamContextStore(database).currentTeamIdForUid("user-1"), "team-1");
});

test("rejects a local user without a team", async (t) => {
  const database = await runtimeTestDatabase(t);
  await assert.rejects(() => new SQLiteTeamContextStore(database).currentTeamIdForUid("user-1"));
});
