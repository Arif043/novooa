import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {runtimeSessions} from "../../../../db/schema.js";
import {testRuntimeWorkspace, withRuntimeTestDatabase} from "../../../../shared/local/local-runtime-test-database.js";
import {LoginName} from "../../domain/entities/login-name.js";
import {RuntimePassword} from "../../domain/entities/runtime-password.js";
import {SQLiteInvitationRepository} from "./sqlite-invitation-repository.js";
import {SQLitePasswordCredentialRepository} from "./sqlite-password-credential-repository.js";
import {SQLiteRuntimeUserRepository} from "./sqlite-runtime-user-repository.js";

const workspace = () => ({teamId: testRuntimeWorkspace.teamId, ownerUid: testRuntimeWorkspace.userId});

test("the workspace profile becomes an account only through setup", () => withRuntimeTestDatabase(async (database) => {
  const users = new SQLiteRuntimeUserRepository(database, workspace);
  assert.deepEqual(await users.list(), [], "ohne Anmeldename ist das Profil noch kein Konto");

  const owner = await users.claimWorkspaceOwner({loginName: LoginName.from("anna"), displayName: "Anna"});

  assert.deepEqual([owner.uid, owner.loginName, owner.role, owner.hasPassword], ["owner-1", "anna", "admin", false]);
  assert.match(owner.createdAt, /^\d{4}-\d{2}-\d{2}T/);
}));

test("accounts are created, found, changed and deleted with everything that hangs on them", () => withRuntimeTestDatabase(async (database) => {
  const users = new SQLiteRuntimeUserRepository(database, workspace);
  const passwords = new SQLitePasswordCredentialRepository(database);
  const ben = await users.create({loginName: LoginName.from("ben"), displayName: "Ben", role: "member"});
  await passwords.set(ben.uid, RuntimePassword.from("geheim1"));
  await database.insert(runtimeSessions).values({token_hash: "hash", uid: ben.uid, expires_at: "2099-01-01T00:00:00.000Z"});

  assert.equal((await users.findByLoginName(LoginName.from("BEN")))?.hasPassword, true);
  assert.equal((await users.update(ben.uid, {role: "admin", displayName: "Ben B."}))?.role, "admin");
  assert.equal(await users.delete(ben.uid), true);

  assert.equal(await users.find(ben.uid), null);
  assert.equal(await passwords.hasAny(), false);
  assert.equal((await database.all(sql`SELECT * FROM runtime_sessions`)).length, 0);
  assert.equal(await users.delete(ben.uid), false);
}));

test("passwords verify only for the right account and can be replaced or removed", () => withRuntimeTestDatabase(async (database) => {
  const passwords = new SQLitePasswordCredentialRepository(database);
  await passwords.set("owner-1", RuntimePassword.from("erstes1"));
  await passwords.set("owner-1", RuntimePassword.from("zweites2"));

  assert.equal(await passwords.verify("owner-1", "erstes1"), false);
  assert.equal(await passwords.verify("owner-1", "zweites2"), true);
  assert.equal(await passwords.verify(null, "zweites2"), false);
  await passwords.remove("owner-1");
  assert.equal(await passwords.verify("owner-1", "zweites2"), false);
}));

test("an invitation code is redeemed once, forgivingly typed, and only before it expires", () => withRuntimeTestDatabase(async (database) => {
  const clock = {now: Date.parse("2026-10-19T00:00:00.000Z")};
  const invitations = new SQLiteInvitationRepository(database, () => clock.now);
  const first = await invitations.issue("owner-1");
  const {code} = await invitations.issue("owner-1");

  assert.match(code, /^[0-9A-HJKMNP-TV-Z]{4}(-[0-9A-HJKMNP-TV-Z]{4}){3}$/);
  assert.equal(await invitations.redeem(first.code), null, "ein neuer Code ersetzt den alten");
  assert.equal(await invitations.redeem(` ${code.toLowerCase().replace(/-/g, " ")} `), "owner-1");
  assert.equal(await invitations.redeem(code), null);

  const late = await invitations.issue("owner-1");
  clock.now += 72 * 60 * 60 * 1000;
  assert.equal(await invitations.redeem(late.code), null);
}));
