import assert from "node:assert/strict";
import test from "node:test";
import {
  type RuntimeLicenseContext,
  type RuntimeLicenseService,
  type RuntimeLicenseStatus,
} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {RuntimeLicenseHttpHandler} from "./local-runtime-license-http-handler.js";
import {type LocalRuntimeRequest, type LocalRuntimeResponse} from "./local-runtime-http-server.js";

test("blocks local business endpoints until the runtime is activated", async () => {
  const application = new FakeApplication();
  const handler = new RuntimeLicenseHttpHandler(new FakeLicenseService(), application);

  const response = await handler.handle({body: {}, method: "GET", url: "/v1/tasks"});

  assert.deepEqual(response, {
    statusCode: 423,
    body: {
      error: "Die lokale Runtime benötigt eine gültige Lizenz.",
      licenseStatus: "notActivated",
      expiresAt: undefined,
    },
  });
  assert.equal(application.requests.length, 0);
});

test("activates the workspace with a customer activation token", async () => {
  const service = new FakeLicenseService();
  const application = new FakeApplication();
  const handler = new RuntimeLicenseHttpHandler(service, application);

  const activation = await handler.handle({
    body: {activationToken: "A3K9N7P2Q4R6"},
    method: "POST",
    url: "/v1/license/activate",
  });
  const taskResponse = await handler.handle({body: {}, method: "GET", url: "/v1/tasks"});

  assert.deepEqual(activation, {
    body: {status: "active", expiresAt: context.expiresAt},
    statusCode: 200,
  });
  assert.deepEqual(application.activated, [context]);
  assert.deepEqual(taskResponse, {body: {status: "delegated"}, statusCode: 200});
});

const context: RuntimeLicenseContext = {
  licenseId: "license-1",
  workspaceId: "workspace-1",
  expiresAt: "2026-09-10T12:00:00.000Z",
};

class FakeLicenseService implements RuntimeLicenseService {
  private active = false;

  async restore(): Promise<RuntimeLicenseContext | null> {
    return null;
  }

  async activate(): Promise<RuntimeLicenseContext> {
    this.active = true;
    return context;
  }

  activeContext(): RuntimeLicenseContext | null {
    return this.active ? context : null;
  }

  signedActiveLicense() {
    return null;
  }

  status(): RuntimeLicenseStatus {
    return this.active ? {state: "active", expiresAt: context.expiresAt} : {state: "notActivated"};
  }
}

class FakeApplication {
  readonly requests: LocalRuntimeRequest[] = [];
  readonly activated: RuntimeLicenseContext[] = [];

  async activate(nextContext: RuntimeLicenseContext): Promise<void> {
    this.activated.push(nextContext);
  }

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse> {
    this.requests.push(request);
    return {body: {status: "delegated"}, statusCode: 200};
  }
}
