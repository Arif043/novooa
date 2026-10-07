import {eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {teamMembers, teams, userProfiles} from "../../../../db/schema.js";
import {ensureLocalRuntimeWorkspace} from "../../../../shared/local/local-runtime-workspace.js";

async function fixture(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await ensureLocalRuntimeWorkspace(database, {teamId: "team-1", teamName: "Erstes Team", userId: "user-1"});
  await database.insert(teams).values({id: "team-2", name: "Zweites Team", owner_uid: "user-1"});
  await database.insert(teamMembers).values({team_id: "team-2", uid: "user-1", role: "member"});
  return database;
}

test("one profile serves multiple memberships with independent team roles", async (t) => {
  const database = await fixture(t);
  await database.update(userProfiles).set({display_name: "Ada", email: "ada@example.org"})
    .where(eq(userProfiles.uid, "user-1"));
  const rows = await database.select({team: teamMembers.team_id, role: teamMembers.role,
    name: userProfiles.display_name, email: userProfiles.email}).from(teamMembers)
    .innerJoin(userProfiles, eq(teamMembers.uid, userProfiles.uid)).orderBy(teamMembers.team_id);
  assert.deepEqual(rows, [
    {team: "team-1", role: "owner", name: "Ada", email: "ada@example.org"},
    {team: "team-2", role: "member", name: "Ada", email: "ada@example.org"},
  ]);
  assert.equal((await database.select().from(userProfiles)).length, 1);
});

test("deleting a team removes only its memberships and preserves the shared profile", async (t) => {
  const database = await fixture(t);
  await database.delete(teams).where(eq(teams.id, "team-1"));
  const [member] = await database.select().from(teamMembers);
  assert.equal(member.team_id, "team-2");
  assert.equal(member.role, "member");
  assert.equal((await database.select().from(userProfiles)).length, 1);
});

test("deleting a profile cascades its memberships without deleting teams", async (t) => {
  const database = await fixture(t);
  await database.delete(userProfiles).where(eq(userProfiles.uid, "user-1"));
  assert.deepEqual(await database.select().from(teamMembers), []);
  assert.equal((await database.select().from(teams)).length, 2);
});

test("memberships require an existing user and team and cannot be duplicated", async (t) => {
  const database = await fixture(t);
  await assert.rejects(database.insert(teamMembers).values({team_id: "team-1", uid: "missing"}));
  await assert.rejects(database.insert(teamMembers).values({team_id: "missing", uid: "user-1"}));
  await assert.rejects(database.insert(teamMembers).values({team_id: "team-1", uid: "user-1"}));
  const columns = await database.all<{name: string}>(sql`PRAGMA table_info(team_members)`);
  assert.ok(!columns.some((column) => ["email", "display_name"].includes(column.name)));
});
