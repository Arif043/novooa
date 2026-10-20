import assert from "node:assert/strict";
import test from "node:test";
import {RuntimeUserError} from "../entities/runtime-user-error.js";
import {CreateUser, DeleteUser, ResetUserPassword, UpdateUser} from "./runtime-user-management.js";
import {MemoryInvitations, MemoryPasswords, MemorySessions, MemoryUsers} from "./runtime-users-test-fakes.js";

function fixture(maxUsers: number | null = null) {
  const users = new MemoryUsers();
  users.put({uid: "owner", loginName: "anna", displayName: "Anna", role: "admin"});
  const passwords = new MemoryPasswords();
  const invitations = new MemoryInvitations();
  const sessions = new MemorySessions();
  const limit = {maxUsers: () => maxUsers};
  return {users, passwords, invitations, sessions,
    create: new CreateUser(users, invitations, limit),
    update: new UpdateUser(users),
    reset: new ResetUserPassword(users, passwords, invitations, sessions),
    remove: new DeleteUser(users, sessions)};
}

function rejectsWith(code: string) {
  return (error: unknown) => error instanceof RuntimeUserError && error.code === code;
}

test("creating a user returns an invitation and respects name and license limit", async () => {
  const {create} = fixture(2);

  const {user, invitation} = await create.execute({loginName: "Ben", displayName: " Ben ", role: "member"});

  assert.deepEqual([user.loginName, user.displayName, user.role], ["ben", "Ben", "member"]);
  assert.equal(invitation.code, `CODE-${user.uid}`);
  await assert.rejects(create.execute({loginName: "carla", displayName: "Carla", role: "member"}), rejectsWith("user_limit_reached"));
});

test("a login name is taken only once", async () => {
  const {create} = fixture();
  await assert.rejects(create.execute({loginName: "ANNA", displayName: "Zweite", role: "member"}), rejectsWith("login_name_taken"));
});

test("the last admin cannot be demoted, another admin can", async () => {
  const {update, users} = fixture();
  await assert.rejects(update.execute("owner", {role: "member"}), rejectsWith("last_admin"));

  users.put({uid: "user-2", loginName: "ben", displayName: "Ben", role: "admin"});

  assert.equal((await update.execute("owner", {role: "member", displayName: "Anna B."})).role, "member");
});

test("resetting a password removes it, ends the sessions and issues a new code", async () => {
  const {reset, users, passwords, sessions} = fixture();
  users.put({uid: "user-2", loginName: "ben", displayName: "Ben", role: "member"});
  passwords.byUid.set("user-2", "alt12345");

  const invitation = await reset.execute("owner", "user-2");

  assert.equal(invitation.code, "CODE-user-2");
  assert.equal(passwords.byUid.has("user-2"), false);
  assert.deepEqual(sessions.revoked, ["user-2"]);
  await assert.rejects(reset.execute("owner", "owner"), rejectsWith("own_account"));
});

test("deleting ends the sessions first; oneself and the workspace owner stay", async () => {
  const {remove, users, sessions} = fixture();
  users.put({uid: "user-2", loginName: "ben", displayName: "Ben", role: "admin"});

  await assert.rejects(remove.execute("user-2", "owner"), rejectsWith("workspace_owner"));
  await assert.rejects(remove.execute("user-2", "user-2"), rejectsWith("own_account"));
  await remove.execute("owner", "user-2");

  assert.deepEqual(sessions.revoked, ["user-2"]);
  assert.equal(await users.find("user-2"), null);
  await assert.rejects(remove.execute("owner", "unbekannt"), rejectsWith("user_not_found"));
});
