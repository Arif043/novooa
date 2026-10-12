import assert from "node:assert/strict";
import test from "node:test";
import {type MlServiceHttp, type MlServiceRequest, type MlServiceResponse} from "../ml-service-http.js";
import {MlTenantIdTakenError, MlTenantSession, type MlTenantTokenStore, type StoredMlTenantToken} from "./ml-tenant-session.js";

test("registers once with the workspace id and reuses the stored token", async () => {
  const service = new FakeMlService();
  const store = new MemoryStore();
  const session = new MlTenantSession(service.http(), store, () => "workspace-a");

  assert.equal(await session.authorization(), "Bearer token-1");
  assert.equal(await new MlTenantSession(service.http(), store, () => "workspace-a").authorization(), "Bearer token-1");
  assert.deepEqual(service.registered, ["workspace-a"]);
});

test("renews only for the token that was rejected", async () => {
  const service = new FakeMlService();
  const session = new MlTenantSession(service.http(), new MemoryStore(), () => "workspace-a");
  await session.authorization();

  await session.renew("Bearer token-1");
  await session.renew("Bearer token-1");

  assert.equal(await session.authorization(), "Bearer token-2");
  assert.equal(service.registered.length, 2);
});

test("unregisters and forgets the token when the license is gone", async () => {
  const service = new FakeMlService();
  const store = new MemoryStore();
  const session = new MlTenantSession(service.http(), store, () => "workspace-a");
  await session.authorization();

  await session.unregister();

  assert.deepEqual(service.released, ["Bearer token-1"]);
  assert.equal(store.token, null);
});

test("needs an active license and reports a taken id clearly", async () => {
  await assert.rejects(new MlTenantSession(new FakeMlService().http(), new MemoryStore(), () => null).authorization(), /aktive Lizenz/);
  const taken = new FakeMlService(409);
  await assert.rejects(new MlTenantSession(taken.http(), new MemoryStore(), () => "workspace-a").authorization(), MlTenantIdTakenError);
});

test("releases the registration of a previous workspace before registering the new one", async () => {
  const service = new FakeMlService();
  const store = new MemoryStore({tenantId: "old-workspace", token: "old"});

  await new MlTenantSession(service.http(), store, () => "workspace-a").authorization();

  assert.deepEqual(service.released, ["Bearer old"]);
  assert.equal(store.token?.tenantId, "workspace-a");
});

class FakeMlService {
  readonly registered: string[] = [];
  readonly released: string[] = [];

  constructor(private readonly registrationStatus = 201) {}

  http(): MlServiceHttp {
    return {send: (request: MlServiceRequest) => this.send(request)} as unknown as MlServiceHttp;
  }

  private async send(request: MlServiceRequest): Promise<MlServiceResponse> {
    if (request.method === "DELETE") {
      this.released.push(request.headers?.authorization ?? "");
      return {status: 200, payload: {}};
    }
    const {tenantId} = JSON.parse(request.body?.() as string) as {tenantId: string};
    this.registered.push(tenantId);
    return {status: this.registrationStatus, payload: {token: `token-${this.registered.length}`}};
  }
}

class MemoryStore implements MlTenantTokenStore {
  constructor(public token: StoredMlTenantToken | null = null) {}

  async load(): Promise<StoredMlTenantToken | null> {
    return this.token;
  }

  async save(token: StoredMlTenantToken): Promise<void> {
    this.token = token;
  }

  async clear(): Promise<void> {
    this.token = null;
  }
}
