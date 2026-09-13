import assert from "node:assert/strict";
import test from "node:test";
import {
  type LocalRuntimeLicenseContext,
  type LocalRuntimeLicenseService,
  type LocalRuntimeLicenseStatus,
} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {LocalRuntimeLicenseHttpHandler} from "./local-runtime-license-http-handler.js";
import {type LocalRuntimeRequest, type LocalRuntimeResponse} from "./local-runtime-http-server.js";

test("blocks local business endpoints until the runtime is activated", async () => {
  const application = new FakeApplication();
  const handler = new LocalRuntimeLicenseHttpHandler(new FakeLicenseService(), application);

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
  const handler = new LocalRuntimeLicenseHttpHandler(service, application);

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

const context: LocalRuntimeLicenseContext = {
  licenseId: "license-1",
  workspaceId: "workspace-1",
  expiresAt: "2026-09-10T12:00:00.000Z",
};

class FakeLicenseService implements LocalRuntimeLicenseService {
  private active = false;

  async restore(): Promise<LocalRuntimeLicenseContext | null> {
    return null;
  }

  async activate(): Promise<LocalRuntimeLicenseContext> {
    this.active = true;
    return context;
  }

  activeContext(): LocalRuntimeLicenseContext | null {
    return this.active ? context : null;
  }

  signedActiveLicense() {
    return null;
  }

  status(): LocalRuntimeLicenseStatus {
    return this.active ? {state: "active", expiresAt: context.expiresAt} : {state: "notActivated"};
  }
}

class FakeApplication {
  readonly requests: LocalRuntimeRequest[] = [];
  readonly activated: LocalRuntimeLicenseContext[] = [];

  async activate(nextContext: LocalRuntimeLicenseContext): Promise<void> {
    this.activated.push(nextContext);
  }

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse> {
    this.requests.push(request);
    return {body: {status: "delegated"}, statusCode: 200};
  }
}
