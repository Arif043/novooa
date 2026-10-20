import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {runtimeSessions} from "../../../../db/schema.js";
import {testRuntimeFieldCipher, testRuntimeWorkspace, withRuntimeTestDatabase} from "../../../../shared/local/local-runtime-test-database.js";
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
  const passwords = new SQLitePasswordCredentialRepository(database, testRuntimeFieldCipher());
  const ben = await users.create({loginName: LoginName.from("ben"), displayName: "Ben", role: "member"});
  await passwords.set(ben.uid, RuntimePassword.from("geheim-passwort1"));
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
  const passwords = new SQLitePasswordCredentialRepository(database, testRuntimeFieldCipher());
  await passwords.set("owner-1", RuntimePassword.from("erstes-passwort1"));
  await passwords.set("owner-1", RuntimePassword.from("zweites-passwort2"));

  assert.equal(await passwords.verify("owner-1", "erstes-passwort1"), false);
  assert.equal(await passwords.verify("owner-1", "zweites-passwort2"), true);
  assert.equal(await passwords.verify(null, "zweites-passwort2"), false);
  await passwords.remove("owner-1");
  assert.equal(await passwords.verify("owner-1", "zweites-passwort2"), false);
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

test("password hashes are stored encrypted and bound to their account", () => withRuntimeTestDatabase(async (database) => {
  const cipher = testRuntimeFieldCipher();
  const passwords = new SQLitePasswordCredentialRepository(database, cipher);
  const ben = await new SQLiteRuntimeUserRepository(database, workspace)
    .create({loginName: LoginName.from("ben"), displayName: "Ben", role: "member"});
  await passwords.set("owner-1", RuntimePassword.from("anna-passwort1"));
  await passwords.set(ben.uid, RuntimePassword.from("ben-passwort12"));

  const rows = await database.all<{uid: string; encrypted_hash: string; salt: string}>(sql`SELECT uid, encrypted_hash, salt FROM runtime_password_credentials`);
  for (const row of rows) assert.equal((JSON.parse(row.encrypted_hash) as {version: number}).version, 1, "ein Umschlag, kein Klartext-Hash");
  const benRow = rows.find((row) => row.uid === ben.uid)!;
  await database.run(sql`UPDATE runtime_password_credentials SET encrypted_hash = ${benRow.encrypted_hash}, salt = ${benRow.salt} WHERE uid = 'owner-1'`);

  assert.equal(await passwords.verify("owner-1", "ben-passwort12"), false, "ein kopierter Umschlag passt nicht zum fremden Konto");
  assert.equal(await passwords.verify(ben.uid, "ben-passwort12"), true);
  const otherKey = new SQLitePasswordCredentialRepository(database, testRuntimeFieldCipher());
  assert.equal(await otherKey.verify(ben.uid, "ben-passwort12"), false, "ohne den Master-Key hilft der Hash nicht");
}));
