import assert from "node:assert/strict";
import test from "node:test";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {
  InvalidActivationTokenError,
  LicenseGatewayUnavailableError,
  LicenseActivationRejectedError,
} from "../../features/licensing/domain/entities/runtime-license-errors.js";
import {ActivateRuntime} from "../../features/licensing/domain/usecases/activate-runtime.js";
import {registerRuntimeLicenseRoutes} from "./local-runtime-license-routes.js";
import {registerLocalRuntimeAccessHooks} from "./local-runtime-access-hooks.js";
import {createLocalRuntimeHttpServer} from "./local-runtime-http-server.js";

test("license status and activation remain public while business routes need both checks", async (t) => {
  const fixture = accessFixture();
  t.after(() => fixture.http.close());
  assert.equal((await fixture.http.inject("/healthz")).statusCode, 200);
  assert.equal((await fixture.http.inject("/v1/license")).statusCode, 200);
  assert.equal((await fixture.http.inject("/v1/tasks")).statusCode, 423);
  assert.deepEqual(fixture.verifiedTokens, []);
  const activation = await fixture.http.inject({method: "POST", url: "/v1/license/activate", payload: {activationToken: "valid"}});
  assert.equal(activation.statusCode, 200);
  assert.equal(fixture.workspaceActivations(), 1);
  assert.equal((await fixture.http.inject("/v1/tasks")).statusCode, 401);
  for (const token of ["invalid", "expired"]) {
    assert.equal((await fixture.http.inject({url: "/v1/tasks", headers: {authorization: `Bearer ${token}`}})).statusCode, 401);
  }
  assert.equal((await fixture.http.inject({url: "/v1/tasks", headers: {authorization: "Bearer valid"}})).statusCode, 200);
});

test("login and setup bypass only session authentication, including query strings", async (t) => {
  const fixture = accessFixture();
  t.after(() => fixture.http.close());
  assert.equal((await fixture.http.inject({method: "POST", url: "/v1/auth/login"})).statusCode, 423);
  await fixture.licenses.activate({activationToken: "valid"});
  for (const url of ["/v1/auth/login?next=1", "/v1/setup", "/v1/setup?next=1"]) {
    assert.equal((await fixture.http.inject({method: "POST", url})).statusCode, 200);
  }
  assert.deepEqual(fixture.verifiedTokens, []);
});

test("release remains session-free and locks subsequent business requests", async (t) => {
  const fixture = accessFixture();
  t.after(() => fixture.http.close());
  await fixture.licenses.activate({activationToken: "valid"});
  assert.equal((await fixture.http.inject({method: "POST", url: "/v1/license/release"})).statusCode, 200);
  assert.equal((await fixture.http.inject({url: "/v1/tasks", headers: {authorization: "Bearer valid"}})).statusCode, 423);
});

test("activation schemas and use-case failures do not start a workspace", async (t) => {
  const fixture = accessFixture();
  t.after(() => fixture.http.close());
  for (const payload of [{}, {activationToken: "   "}, {activationToken: "x".repeat(401)}]) {
    assert.equal((await fixture.http.inject({method: "POST", url: "/v1/license/activate", payload})).statusCode, 400);
  }
  assert.equal((await fixture.http.inject({method: "POST", url: "/v1/license/activate", payload: {activationToken: "invalid"}})).statusCode, 401);
  assert.equal(fixture.workspaceActivations(), 0);
});

const activationFailures: Record<string, () => Error> = {
  malformed: () => new InvalidActivationTokenError(),
  offline: () => new LicenseGatewayUnavailableError("ECONNREFUSED"),
  broken: () => new Error("Signatur passt nicht"),
};

test("activation failures are reported with distinguishable status codes", async (t) => {
  const fixture = accessFixture();
  t.after(() => fixture.http.close());
  const expected = [["malformed", 400, "invalid_token"], ["invalid", 401, "license_rejected"],
    ["offline", 502, "gateway_unavailable"], ["broken", 500, "activation_failed"]] as const;
  for (const [activationToken, statusCode, code] of expected) {
    const response = await fixture.http.inject({method: "POST", url: "/v1/license/activate", payload: {activationToken}});
    assert.equal(response.statusCode, statusCode);
    assert.equal(response.json<{code: string}>().code, code);
  }
});

test("re-submitting a token on a licensed runtime confirms the active license", async (t) => {
  const fixture = accessFixture();
  t.after(() => fixture.http.close());
  await fixture.http.inject({method: "POST", url: "/v1/license/activate", payload: {activationToken: "valid"}});
  const again = await fixture.http.inject({method: "POST", url: "/v1/license/activate", payload: {activationToken: "invalid"}});
  assert.equal(again.statusCode, 200);
  assert.equal(again.json<{status: string}>().status, "active");
});

function accessFixture() {
  let active = false;
  let activatedWorkspaces = 0;
  const licenses: RuntimeLicenseService = {
    restore: async () => null,
    activate: async ({activationToken}) => {
      const failure = activationFailures[activationToken];
      if (failure !== undefined) throw failure();
      if (activationToken !== "valid") throw new LicenseActivationRejectedError();
      active = true; return context;
    },
    release: async () => { active = false; },
    activeContext: () => active ? context : null,
    status: () => active ? {state: "active"} : {state: "notActivated"},
    signedActiveLicense: () => null, activeActivation: () => null,
  };
  const verifiedTokens: string[] = [];
  const http = accessHttp(licenses, verifiedTokens, async () => { activatedWorkspaces += 1; });
  return {http, licenses, verifiedTokens, workspaceActivations: () => activatedWorkspaces};
}

function accessHttp(licenses: RuntimeLicenseService, verifiedTokens: string[], activate: () => Promise<void>) {
  return createLocalRuntimeHttpServer(async (routes) => {
    registerRuntimeLicenseRoutes(routes, licenses, new ActivateRuntime(licenses, activate));
    routes.register(async (api) => {
      registerLocalRuntimeAccessHooks(api, licenses, {verifySession: async (token) => {
        verifiedTokens.push(token); return token === "valid";
      }});
      api.get("/v1/tasks", async () => ({ok: true}));
      api.post("/v1/auth/login", async () => ({token: "valid"}));
      api.post("/v1/setup", async () => ({ok: true}));
    });
  });
}

const context = {licenseId: "test", licenseName: "Test", workspaceId: "workspace", expiresAt: "2099-01-01T00:00:00.000Z"};
