import assert from "node:assert/strict";
import test from "node:test";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {LocalRuntimeSessionStore} from "../../../../shared/local/local-runtime-session-store.js";
import {testRuntimeWorkspace, withRuntimeTestDatabase} from "../../../../shared/local/local-runtime-test-database.js";
import {accountRoutes} from "./local-runtime-account-routes.js";
import {userRoutes} from "./local-runtime-user-routes.js";
import {createRuntimeUsersModule} from "./runtime-users-composition.js";
import {type RuntimeDatabase} from "../../../../db/database.js";

const owner = {uid: testRuntimeWorkspace.userId, role: "admin" as const};

function routesFor(database: RuntimeDatabase, maxUsers: number | null = null) {
  const sessions = new LocalRuntimeSessionStore(database, () => testRuntimeWorkspace.teamId);
  const topics: string[] = [];
  const module = createRuntimeUsersModule({
    database, sessions, connections: {closeInactive: async () => undefined},
    workspace: () => ({teamId: testRuntimeWorkspace.teamId, ownerUid: testRuntimeWorkspace.userId}),
    proof: {requiresActivationTokenForSetup: () => true, matchesActivationToken: (token) => token === "LIZENZ"},
    limit: {maxUsers: () => maxUsers}, notifier: {publish: (topic) => topics.push(topic)},
  });
  return {
    sessions, topics,
    account: testingRoutes(accountRoutes, module.account, {}, owner),
    users: testingRoutes(userRoutes, module.users, {}, owner),
  };
}

test("setup, sign-in and me run through one account", () => withRuntimeTestDatabase(async (database) => {
  const {account, sessions} = routesFor(database);
  assert.deepEqual((await account.handle({url: "/v1/setup", body: undefined}))?.body, {needsSetup: true, requiresLicenseToken: true});

  const setup = await account.handle({method: "POST", url: "/v1/setup",
    body: {activationToken: "LIZENZ", loginName: "Anna", displayName: "Anna", password: "geheim1"}});
  assert.equal(setup?.statusCode, 201);
  assert.equal((await account.handle({method: "POST", url: "/v1/setup",
    body: {activationToken: "LIZENZ", loginName: "zweit", displayName: "Zweit", password: "geheim1"}}))?.statusCode, 409);

  const wrong = await account.handle({method: "POST", url: "/v1/auth/login", body: {loginName: "anna", password: "falsch1"}});
  assert.deepEqual(wrong, {statusCode: 401, body: {error: "Anmeldename oder Passwort ist ungültig.", code: "invalid_credentials"}});
  const login = await account.handle({method: "POST", url: "/v1/auth/login", body: {loginName: "anna", password: "geheim1"}});
  const {token} = login?.body as {token: string};
  assert.deepEqual(await sessions.verifySession(token), owner);

  const me = await account.handle({url: "/v1/auth/me", body: undefined});
  assert.equal((me?.body as {loginName: string}).loginName, "anna");
}));

test("an admin invites a member who sets a password with the code", () => withRuntimeTestDatabase(async (database) => {
  const {account, users, sessions, topics} = routesFor(database, 2);
  await account.handle({method: "POST", url: "/v1/setup",
    body: {activationToken: "LIZENZ", loginName: "anna", displayName: "Anna", password: "geheim1"}});

  const created = await users.handle({method: "POST", url: "/v1/users", body: {loginName: "ben", displayName: "Ben", role: "member"}});
  assert.equal(created?.statusCode, 201);
  const {user, invitation} = created?.body as {user: {uid: string; hasPassword: boolean}; invitation: {code: string}};
  assert.equal(user.hasPassword, false);
  assert.equal((await users.handle({method: "POST", url: "/v1/users", body: {loginName: "carla", displayName: "Carla", role: "member"}}))
    ?.statusCode, 409, "die Lizenz erlaubt zwei Benutzer");

  const redeemed = await account.handle({method: "POST", url: "/v1/auth/invitations/redeem", body: {code: invitation.code, password: "eigenes1"}});
  assert.deepEqual(await sessions.verifySession((redeemed?.body as {token: string}).token), {uid: user.uid, role: "member"});

  const list = await users.handle({url: "/v1/users", body: undefined});
  assert.deepEqual((list?.body as {items: {loginName: string; hasPassword: boolean}[]; maxUsers: number}).items
    .map((item) => [item.loginName, item.hasPassword]), [["anna", true], ["ben", true]]);
  assert.equal((await users.handle({method: "DELETE", url: `/v1/users/${user.uid}`, body: undefined}))?.statusCode, 204);
  assert.equal((await users.handle({method: "DELETE", url: `/v1/users/${owner.uid}`, body: undefined}))?.statusCode, 409);
  assert.deepEqual(topics, ["users", "users"]);
}));
