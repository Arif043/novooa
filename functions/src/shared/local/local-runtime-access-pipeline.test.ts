import assert from "node:assert/strict";
import test from "node:test";
import {type RuntimeLicenseContext, type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {createLocalRuntimeAccessPipeline} from "./local-runtime-access-pipeline.js";
import {type LocalRuntimeRequest, type LocalRuntimeResponse} from "./local-runtime-http-server.js";

test("checks the license before attempting session verification", async () => {
  const fixture = accessFixture(false);
  const response = await fixture.handler.handle(requestFor("/v1/tasks", "valid"));
  assert.equal(response?.statusCode, 423);
  assert.deepEqual(fixture.verifiedTokens, []);
  assert.deepEqual(fixture.application.requests, []);
});

test("rejects missing, invalid and expired sessions before reaching the application", async () => {
  const fixture = accessFixture(true);
  for (const token of [undefined, "invalid", "expired"]) {
    const response = await fixture.handler.handle(requestFor("/v1/tasks", token));
    assert.equal(response?.statusCode, 401);
  }
  assert.deepEqual(fixture.application.requests, []);
  assert.deepEqual(fixture.verifiedTokens, ["invalid", "expired"]);
});

test("delegates business requests only after license and session checks", async () => {
  const fixture = accessFixture(true);
  const request = requestFor("/v1/tasks", "valid");
  assert.equal((await fixture.handler.handle(request))?.statusCode, 200);
  assert.deepEqual(fixture.verifiedTokens, ["valid"]);
  assert.deepEqual(fixture.application.requests, [request]);
});

test("keeps license status and activation reachable without a session", async () => {
  const fixture = accessFixture(false);
  const status = await fixture.handler.handle(requestFor("/v1/license"));
  const activation = await fixture.handler.handle({
    method: "POST", url: "/v1/license/activate", body: {activationToken: "activation-token"},
  });
  assert.equal(status?.statusCode, 200);
  assert.equal(activation?.statusCode, 200);
  assert.deepEqual(fixture.application.activated, [context]);
  assert.deepEqual(fixture.verifiedTokens, []);
  assert.equal((await fixture.handler.handle(requestFor("/v1/tasks")))?.statusCode, 401);
});

test("preserves session-free license release and blocks subsequent business requests", async () => {
  const fixture = accessFixture(true);
  const release = await fixture.handler.handle({method: "POST", url: "/v1/license/release", body: {}});
  assert.equal(release?.statusCode, 200);
  assert.equal((await fixture.handler.handle(requestFor("/v1/tasks", "valid")))?.statusCode, 423);
  assert.deepEqual(fixture.verifiedTokens, []);
});

test("passes login and pairing-code setup through without a session after activation", async () => {
  const fixture = accessFixture(true);
  for (const url of ["/v1/auth/login", "/v1/setup"]) {
    assert.equal((await fixture.handler.handle({method: "POST", url, body: {}}))?.statusCode, 200);
  }
  assert.deepEqual(fixture.verifiedTokens, []);
  assert.equal(fixture.application.requests.length, 2);
});

test("still requires a license for login and setup", async () => {
  const fixture = accessFixture(false);
  for (const url of ["/v1/auth/login", "/v1/setup"]) {
    assert.equal((await fixture.handler.handle({method: "POST", url, body: {}}))?.statusCode, 423);
  }
  assert.deepEqual(fixture.application.requests, []);
});

function requestFor(url: string, token?: string): LocalRuntimeRequest {
  return {method: "GET", url, body: {}, headers: token ? {authorization: `Bearer ${token}`} : {}};
}

function accessFixture(initiallyActive: boolean) {
  let active = initiallyActive;
  const licenses: RuntimeLicenseService = {
    restore: async () => active ? context : null,
    activate: async () => { active = true; return context; },
    release: async () => { active = false; },
    activeContext: () => active ? context : null,
    signedActiveLicense: () => null, activeActivation: () => null,
    status: () => active ? {state: "active", expiresAt: context.expiresAt} : {state: "notActivated"},
  };
  const verifiedTokens: string[] = [];
  const sessions = {verifySession: async (token: string) => {
    verifiedTokens.push(token);
    return token === "valid";
  }};
  const application = new FakeApplication();
  return {handler: createLocalRuntimeAccessPipeline(licenses, sessions, application), application, verifiedTokens};
}

const context: RuntimeLicenseContext = {
  licenseId: "license-1", licenseName: "Test", workspaceId: "workspace-1", expiresAt: "2099-01-01T00:00:00.000Z",
};

class FakeApplication {
  readonly requests: LocalRuntimeRequest[] = [];
  readonly activated: RuntimeLicenseContext[] = [];
  async activate(activation: RuntimeLicenseContext): Promise<void> { this.activated.push(activation); }
  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse> {
    this.requests.push(request);
    return {body: {ok: true}, statusCode: 200};
  }
}
