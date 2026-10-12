import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import test, {type TestContext} from "node:test";
import {WebSocket} from "ws";
import {connectRuntimeDatabase} from "../../db/database.js";
import {type RuntimeLicenseContext} from "../../features/licensing/domain/entities/runtime-license-context.js";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {CurrentRuntimeFieldCipher} from "../../features/runtime_security/infrastructure/current-runtime-field-cipher.js";
import {createRuntimeKeyring} from "../../features/runtime_security/infrastructure/runtime-keyring.js";
import {RuntimeSecretFileAccess} from "../../features/runtime_security/infrastructure/runtime-secret-file-access.js";
import {LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";
import {openLocalRuntimeDatabase} from "./local-runtime-database.js";
import {bootstrapLocalRuntime} from "./local-runtime-server-bootstrap.js";

test("native routes support activation, setup, login and protected workspace access", async (t) => {
  const {base} = await activatedRuntimeFixture(t);
  assert.equal((await fetch(`${base}/v1/tasks`)).status, 423);
  assert.equal((await postJson(base, "/v1/license/activate", {activationToken: "test-license"})).status, 200);
  assert.equal((await fetch(`${base}/v1/tasks`)).status, 401);
  assert.equal((await fetch(`${base}/v1/setup`)).status, 200);
  assert.equal((await postJson(base, "/v1/setup", {activationToken: "foreign", password: "x"})).status, 403);
  const setup = await postJson(base, "/v1/setup", {activationToken: "test-license", password: "test-password"});
  assert.equal(setup.status, 204);
  assert.equal(await setup.text(), "");
  const login = await postJson(base, "/v1/auth/login", {password: "test-password"});
  assert.equal(login.status, 200);
  const {token} = await login.json() as {token: string};
  const response = await fetch(`${base}/v1/tasks`, {headers: {authorization: `Bearer ${token}`}});
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {items: []});
  const secondLogin = await postJson(base, "/v1/auth/login", {password: "test-password"});
  const {token: otherToken} = await secondLogin.json() as {token: string};
  const revoke = await fetch(`${base}/v1/auth/sessions/revoke-others`, {
    method: "POST", headers: {"content-type": "application/json", authorization: `Bearer ${token}`}, body: "{}",
  });
  assert.deepEqual(await revoke.json(), {revoked: 1});
  assert.equal((await fetch(`${base}/v1/tasks`, {headers: {authorization: `Bearer ${otherToken}`}})).status, 401);
  assert.equal((await fetch(`${base}/v1/tasks`, {headers: {authorization: `Bearer ${token}`}})).status, 200);
  assert.equal((await postJson(base, "/v1/license/release", {})).status, 401);
  const release = await fetch(`${base}/v1/license/release`, {
    method: "POST", headers: {"content-type": "application/json", authorization: `Bearer ${token}`}, body: "{}",
  });
  assert.equal(release.status, 200);
  assert.equal((await fetch(`${base}/v1/tasks`, {headers: {authorization: `Bearer ${token}`}})).status, 423);
});

async function activatedRuntimeFixture(t: TestContext) {
  const runtimeRoot = await mkdtemp(join(tmpdir(), "novooa-fastify-runtime-"));
  t.after(() => rm(runtimeRoot, {recursive: true, force: true}));
  const database = await openLocalRuntimeDatabase({databasePath: ":memory:",
    migrationsDirectory: resolve(__dirname, "../../../drizzle")});
  const runtime = await bootstrapLocalRuntime({database, runtimeRoot,
    fieldCipher: new CurrentRuntimeFieldCipher(JSON.stringify(createRuntimeKeyring())), secretFileAccess: new RuntimeSecretFileAccess(), licenses: activatableLicenses(),
    cors: LocalRuntimeCorsPolicy.fromEnvironment(), webDirectory: undefined, port: 0});
  let closed = false;
  const closeHttp = async () => { if (!closed) { closed = true; await runtime.closeHttp(); } };
  t.after(async () => {await closeHttp(); await runtime.application.stop(); database.$client.close();});
  const address = runtime.server.address();
  assert.ok(address && typeof address !== "string");
  return {base: `http://127.0.0.1:${address.port}`, port: address.port, closeHttp};
}

function activatableLicenses(): RuntimeLicenseService {
  let active: RuntimeLicenseContext | null = null;
  return {...inactiveLicenses(), activeContext: () => active,
    matchesActivationToken: (token) => active !== null && token === "test-license",
    activate: async () => {
      active = {licenseId: "test-license", licenseName: "Standalone", workspaceId: "test-workspace", expiresAt: "2030-01-01"};
      return active;
    }, release: async () => {active = null;}};
}

function postJson(base: string, path: string, body: unknown): Promise<Response> {
  return fetch(`${base}${path}`, {method: "POST", headers: {"content-type": "application/json"}, body: JSON.stringify(body)});
}

test("starts the runtime HTTP server with the new keyring configuration", async () => {
  const database = connectRuntimeDatabase(":memory:");
  const {server, application, closeHttp} = await bootstrapLocalRuntime({
    database, runtimeRoot: "/unused", fieldCipher: new CurrentRuntimeFieldCipher(JSON.stringify(createRuntimeKeyring())), secretFileAccess: new RuntimeSecretFileAccess(),
    licenses: inactiveLicenses(), cors: LocalRuntimeCorsPolicy.fromEnvironment(), webDirectory: undefined, port: 0,
  });
  try {
    const address = server.address();
    assert.ok(address && typeof address !== "string");
    const response = await fetch(`http://127.0.0.1:${address.port}/healthz`);
    assert.equal(response.status, 200);
  } finally {
    await closeHttp();
    await application.stop();
    database.$client.close();
  }
});

test("Fastify shutdown terminates active realtime connections", async (t) => {
  const {base, port, closeHttp} = await activatedRuntimeFixture(t);
  await postJson(base, "/v1/license/activate", {activationToken: "test-license"});
  await postJson(base, "/v1/setup", {activationToken: "test-license", password: "test-password"});
  const {token} = await (await postJson(base, "/v1/auth/login", {password: "test-password"})).json() as {token: string};
  const ticketResponse = await fetch(`${base}/v1/realtime/ticket`, {method: "POST", headers: {authorization: `Bearer ${token}`}});
  const {ticket} = await ticketResponse.json() as {ticket: string};
  const socket = new WebSocket(`ws://127.0.0.1:${port}/v1/realtime?ticket=${ticket}`);
  t.after(() => socket.terminate());
  await new Promise<void>((resolve, reject) => { socket.once("open", resolve); socket.once("error", reject); });
  const closed = new Promise<void>((resolve) => socket.once("close", () => resolve()));
  await closeHttp();
  await closed;
  assert.equal(socket.readyState, WebSocket.CLOSED);
});

function inactiveLicenses(): RuntimeLicenseService {
  return {
    restore: async () => null,
    activate: async () => { throw new Error("Keine Test-Aktivierung."); },
    release: async () => {}, activeContext: () => null,
    signedActiveLicense: () => null, activeActivation: () => null,
    status: () => ({state: "notActivated"}),
    matchesActivationToken: () => false, requiresActivationTokenForSetup: () => true,
    verifyActivation: async () => "notActivated",
  };
}
