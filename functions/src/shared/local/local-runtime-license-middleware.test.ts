import assert from "node:assert/strict";
import test from "node:test";
import {
  type RuntimeLicenseContext,
  type RuntimeLicenseService,
  type RuntimeLicenseStatus,
} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {RuntimeLicenseMiddleware} from "./local-runtime-license-middleware.js";
import {type LocalRuntimeRequest, type LocalRuntimeResponse} from "./local-runtime-http-server.js";

test("blocks local business endpoints until the runtime is activated", async () => {
  const application = new FakeApplication();
  const handler = new RuntimeLicenseMiddleware(new FakeLicenseService(), (next) => application.activate(next), application);
  const response = await handler.handle({body: {}, method: "GET", url: "/v1/tasks"});

  assert.deepEqual(response, {
    statusCode: 423,
    body: {error: "Die Runtime benötigt eine gültige Lizenz.", licenseStatus: "notActivated", expiresAt: undefined},
  });
  assert.equal(application.requests.length, 0);
});

test("activates and releases the local workspace", async () => {
  const service = new FakeLicenseService();
  const application = new FakeApplication();
  const handler = new RuntimeLicenseMiddleware(service, (next) => application.activate(next), application);
  const activation = await handler.handle({body: {activationToken: "A3K9N7P2Q4R6"}, method: "POST", url: "/v1/license/activate"});
  const release = await handler.handle({body: {}, method: "POST", url: "/v1/license/release"});

  assert.deepEqual(activation, {body: {status: "active", expiresAt: context.expiresAt, name: context.licenseName}, statusCode: 200});
  assert.deepEqual(release, {body: {status: "notActivated"}, statusCode: 200});
  assert.deepEqual(application.activated, [context]);
  assert.equal(service.released, true);
});

test("keeps the activation callback separate from the downstream request handler", async () => {
  const service = new FakeLicenseService();
  const activated: RuntimeLicenseContext[] = [];
  let requestCount = 0;
  const inner = {handle: async () => {
    requestCount += 1;
    return {body: {ok: true}, statusCode: 200};
  }};
  const handler = new RuntimeLicenseMiddleware(service, async (next) => { activated.push(next); }, inner);
  await handler.handle({method: "POST", url: "/v1/license/activate", body: {activationToken: "test-token"}});
  assert.deepEqual(activated, [context]);
  assert.equal(requestCount, 0);
  assert.equal((await handler.handle({method: "GET", url: "/v1/tasks", body: {}}))?.statusCode, 200);
  assert.equal(requestCount, 1);
  assert.equal(activated.length, 1);
});

test("returns an activation error when the callback fails without delegating the request", async () => {
  const inner = {handle: async () => { throw new Error("Must not delegate activation."); }};
  const handler = new RuntimeLicenseMiddleware(new FakeLicenseService(), async () => {
    throw new Error("Workspace activation failed.");
  }, inner);
  const response = await handler.handle({method: "POST", url: "/v1/license/activate", body: {activationToken: "test-token"}});
  assert.equal(response?.statusCode, 401);
});

const context: RuntimeLicenseContext = {
  licenseId: "license-1", licenseName: "Beispiel GmbH", workspaceId: "workspace-1", expiresAt: "2026-09-10T12:00:00.000Z",
};

class FakeLicenseService implements RuntimeLicenseService {
  private active = false;
  released = false;
  async restore(): Promise<RuntimeLicenseContext | null> { return null; }
  async activate(): Promise<RuntimeLicenseContext> { this.active = true; return context; }
  async release(): Promise<void> { this.active = false; this.released = true; }
  activeContext(): RuntimeLicenseContext | null { return this.active ? context : null; }
  signedActiveLicense() { return null; }
  activeActivation() { return null; }
  status(): RuntimeLicenseStatus { return this.active ? {state: "active", expiresAt: context.expiresAt} : {state: "notActivated"}; }
}

class FakeApplication {
  readonly requests: LocalRuntimeRequest[] = [];
  readonly activated: RuntimeLicenseContext[] = [];
  async activate(nextContext: RuntimeLicenseContext): Promise<void> { this.activated.push(nextContext); }
  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse> {
    this.requests.push(request);
    return {body: {status: "delegated"}, statusCode: 200};
  }
}
