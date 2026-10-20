import assert from "node:assert/strict";
import test from "node:test";
import {RuntimeUserError} from "../entities/runtime-user-error.js";
import {RecoverAdminAccess, RedeemInvitation, SetUpFirstAdmin, SignIn} from "./runtime-access.js";
import {licenseProof, MemoryInvitations, MemoryPasswords, MemorySessions, MemoryUsers} from "./runtime-users-test-fakes.js";

function fixture() {
  const users = new MemoryUsers();
  const passwords = new MemoryPasswords();
  const invitations = new MemoryInvitations();
  const sessions = new MemorySessions();
  return {users, passwords, invitations, sessions,
    setUp: new SetUpFirstAdmin(users, passwords, licenseProof),
    signIn: new SignIn(users, passwords, sessions),
    redeem: new RedeemInvitation(invitations, passwords, sessions),
    recover: new RecoverAdminAccess(users, passwords, licenseProof, sessions)};
}

function rejectsWith(code: string) {
  return (error: unknown) => error instanceof RuntimeUserError && error.code === code;
}

const admin = {activationToken: "LIZENZ", loginName: " Anna ", displayName: "Anna Admin", password: "geheim-passwort1"};

test("setup turns the workspace profile into the first admin, exactly once", async () => {
  const {setUp, passwords} = fixture();

  const owner = await setUp.execute(admin);

  assert.deepEqual([owner.uid, owner.loginName, owner.role, owner.hasPassword], ["owner", "anna", "admin", true]);
  assert.equal(passwords.byUid.get("owner"), "geheim-passwort1");
  await assert.rejects(setUp.execute(admin), rejectsWith("already_set_up"));
});

test("setup needs the license token and a valid account", async () => {
  const {setUp, passwords} = fixture();

  await assert.rejects(setUp.execute({...admin, activationToken: "FALSCH"}), rejectsWith("license_token_mismatch"));
  await assert.rejects(setUp.execute({...admin, loginName: "a"}), rejectsWith("invalid_input"));
  await assert.rejects(setUp.execute({...admin, password: "kurz"}), rejectsWith("invalid_input"));
  assert.equal(passwords.byUid.size, 0);
});

test("sign-in names neither the missing account nor the wrong password", async () => {
  const {setUp, signIn, sessions} = fixture();
  await setUp.execute(admin);

  for (const attempt of [{loginName: "anna", password: "falsch"}, {loginName: "niemand", password: "geheim-passwort1"}, {loginName: "!", password: "x"}]) {
    await assert.rejects(signIn.execute(attempt), rejectsWith("invalid_credentials"));
  }
  assert.equal(await signIn.execute({loginName: "ANNA", password: "geheim-passwort1"}), "token-owner");
  assert.deepEqual(sessions.created, ["owner"]);
});

test("an invitation sets the password once and signs the person in", async () => {
  const {redeem, invitations, passwords} = fixture();
  invitations.byCode.set("CODE", "user-7");

  assert.equal(await redeem.execute({code: "CODE", password: "eigenes-passwort1"}), "token-user-7");
  assert.equal(passwords.byUid.get("user-7"), "eigenes-passwort1");
  await assert.rejects(redeem.execute({code: "CODE", password: "eigenes-passwort1"}), rejectsWith("invalid_invitation"));
});

test("recovery with the license token resets an admin and ends the old sessions", async () => {
  const {setUp, recover, users, passwords, sessions} = fixture();
  await setUp.execute(admin);
  users.put({uid: "user-2", loginName: "ben", displayName: "Ben", role: "member"});

  await assert.rejects(recover.execute({activationToken: "FALSCH", loginName: "anna", password: "neues-passwort1"}),
    rejectsWith("license_token_mismatch"));
  await assert.rejects(recover.execute({activationToken: "LIZENZ", loginName: "ben", password: "neues-passwort1"}),
    rejectsWith("user_not_found"));
  assert.equal(await recover.execute({activationToken: "LIZENZ", loginName: "anna", password: "neues-passwort1"}), "token-owner");
  assert.equal(passwords.byUid.get("owner"), "neues-passwort1");
  assert.deepEqual(sessions.revoked, ["owner"]);
});
