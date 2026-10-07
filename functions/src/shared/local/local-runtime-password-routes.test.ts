import assert from "node:assert/strict";
import test from "node:test";
import {registerLocalRuntimeAccessHooks} from "./local-runtime-access-hooks.js";
import {createLocalRuntimeHttpServer} from "./local-runtime-http-server.js";
import {passwordRoutes} from "./local-runtime-password-routes.js";

test("password changes require an active license and valid operator session", async (t) => {
  const fixture = passwordFixture();
  t.after(() => fixture.http.close());
  assert.equal((await fixture.change()).statusCode, 423);
  fixture.activate();
  assert.equal((await fixture.change()).statusCode, 401);
  assert.equal((await fixture.change("expired")).statusCode, 401);
  assert.deepEqual(fixture.passwords, []);
  assert.equal((await fixture.change("valid")).statusCode, 204);
  assert.deepEqual(fixture.passwords, ["  new-password  "]);
});

test("invalid passwords are rejected before changing stored credentials", async (t) => {
  const fixture = passwordFixture();
  t.after(() => fixture.http.close());
  fixture.activate();
  for (const payload of [{}, {password: ""}, {password: "short"}, {password: "x".repeat(1001)}]) {
    const response = await fixture.http.inject({method: "PUT", url: "/v1/auth/password",
      headers: {authorization: "Bearer valid"}, payload});
    assert.equal(response.statusCode, 400);
  }
  assert.deepEqual(fixture.passwords, []);
});

test("storage errors cannot report a successful change", async (t) => {
  const fixture = passwordFixture(true);
  t.after(() => fixture.http.close());
  fixture.activate();
  assert.equal((await fixture.change("valid")).statusCode, 500);
});

function passwordFixture(fail = false) {
  let active = false;
  const passwords: string[] = [];
  const http = createLocalRuntimeHttpServer(async (routes) => {
    await routes.register(async (api) => {
      registerLocalRuntimeAccessHooks(api, {
        activeContext: () => active ? {licenseId: "test", licenseName: "Test", workspaceId: "workspace", expiresAt: "2099-01-01"} : null,
        status: () => ({state: "notActivated"}),
      }, {verifySession: async (token) => token === "valid"});
      await api.register(passwordRoutes, {credentials: {updatePassword: async (password) => {
        if (fail) throw new Error("Storage unavailable");
        passwords.push(password);
      }}});
    });
  });
  const change = (token?: string) => http.inject({method: "PUT", url: "/v1/auth/password",
    headers: token ? {authorization: `Bearer ${token}`} : {}, payload: {password: "  new-password  "}});
  return {http, passwords, change, activate: () => { active = true; }};
}
