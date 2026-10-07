import {and, eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {runtimeTestDatabase} from "../../db/runtime-database-test-support.js";
import {teamMembers, teams, userProfiles} from "../../db/schema.js";
import {ensureLocalRuntimeWorkspace} from "./local-runtime-workspace.js";

const workspace = {teamId: "local-team", teamName: "Lokaler Arbeitsbereich", userId: "local-user"};

test("creates the initial local workspace, user profile and membership only once", async (t) => {
  const database = await runtimeTestDatabase(t);
  await ensureLocalRuntimeWorkspace(database, workspace);
  await ensureLocalRuntimeWorkspace(database, workspace);
  const team = await database.select().from(teams).where(eq(teams.id, workspace.teamId)).get();
  assert.equal(team?.name, workspace.teamName);
  assert.equal(team?.owner_uid, workspace.userId);
  const [member] = await database.select().from(teamMembers);
  assert.equal(member.role, "owner");
  assert.equal(member.uid, workspace.userId);
  const [profile] = await database.select().from(userProfiles);
  assert.equal(profile.display_name, "Lokaler Benutzer");
  assert.equal(profile.email, "");
});

test("workspace initialization preserves an existing profile and team membership", async (t) => {
  const database = await runtimeTestDatabase(t);
  await ensureLocalRuntimeWorkspace(database, workspace);
  await database.update(userProfiles).set({display_name: "Ada", email: "ada@example.org"})
    .where(eq(userProfiles.uid, workspace.userId));
  await database.update(teamMembers).set({role: "member"}).where(and(
    eq(teamMembers.team_id, workspace.teamId), eq(teamMembers.uid, workspace.userId)));
  await ensureLocalRuntimeWorkspace(database, workspace);
  const [profile] = await database.select().from(userProfiles);
  assert.equal(profile.display_name, "Ada");
  assert.equal(profile.email, "ada@example.org");
  assert.equal((await database.select().from(teamMembers))[0].role, "member");
});

test("a failed membership creation rolls back the new user profile and team", async (t) => {
  const database = await runtimeTestDatabase(t);
  await database.run(sql`CREATE TRIGGER reject_membership BEFORE INSERT ON team_members
    BEGIN SELECT RAISE(ABORT, 'Mitgliedschaft fehlgeschlagen'); END`);
  await assert.rejects(ensureLocalRuntimeWorkspace(database, workspace));
  assert.deepEqual(await database.select().from(userProfiles), []);
  assert.deepEqual(await database.select().from(teamMembers), []);
  assert.equal(await database.select().from(teams).where(eq(teams.id, workspace.teamId)).get(), undefined);
});
