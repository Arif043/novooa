import assert from "node:assert/strict";
import {generateKeyPairSync} from "node:crypto";
import test from "node:test";
import {type RuntimeLicenseActivation} from "../../domain/entities/runtime-license-activation.js";
import {type SignedRuntimeLicense} from "../../domain/entities/runtime-license-lease.js";
import {LicenseGatewayUnavailableError} from "../../domain/entities/runtime-license-errors.js";
import {type RuntimeLicenseVerdict} from "../../domain/entities/runtime-license-verification.js";
import {signRuntimeLicense} from "../license-lease-crypto.js";
import {
  type RuntimeLicenseStore,
} from "./file-local-runtime-license-store.js";
import {type RuntimeLicenseGatewayClient} from "./local-runtime-license-gateway-client.js";
import {GatewayRuntimeLicenseService} from "./local-runtime-license-manager.js";

const activationToken = "A3K9N7P2Q4R6T8W5";

test("stores a signed activation without persisting the customer token", async () => {
  const keys = ed25519Keys();
  const store = new MemoryStore();
  const gateway = new GatewayFake(signedLicense(keys.privateKey, futureDate()));
  const runtime = service(store, gateway, keys.publicKey);

  const context = await runtime.activate({activationToken});

  assert.equal(context.workspaceId, "workspace-1");
  assert.deepEqual(gateway.tokens, [activationToken]);
  assert.equal(store.state?.activationSecret, "activation-secret");
  assert.doesNotMatch(JSON.stringify(store.state), new RegExp(activationToken));
});

test("releases the exact active installation and clears local state", async () => {
  const keys = ed25519Keys();
  const store = new MemoryStore();
  const gateway = new GatewayFake(signedLicense(keys.privateKey, futureDate()));
  const runtime = service(store, gateway, keys.publicKey);
  await runtime.activate({activationToken});

  await runtime.release();

  assert.equal(store.state, undefined);
  assert.equal(gateway.releases.length, 1);
  assert.equal(gateway.releases[0].activationSecret, "activation-secret");
  assert.deepEqual(runtime.status(), {state: "notActivated"});
});

test("a revoked activation locks the runtime and clears local state", async () => {
  const {runtime, store, gateway} = await activatedRuntime();
  gateway.verdict = "revoked";

  assert.equal(await runtime.verifyActivation(), "revoked");

  assert.equal(store.state, undefined);
  assert.equal(runtime.activeContext(), null);
  assert.equal(gateway.releases.length, 0, "eine widerrufene Lizenz wird nicht zusätzlich freigegeben");
});

test("an unreachable gateway keeps the runtime active", async () => {
  const {runtime, store, gateway} = await activatedRuntime();
  gateway.verdict = new LicenseGatewayUnavailableError("HTTP 503");

  await assert.rejects(runtime.verifyActivation(), LicenseGatewayUnavailableError);

  assert.notEqual(store.state, undefined);
  assert.notEqual(runtime.activeContext(), null);
});

test("an active verdict keeps the license and a runtime without license skips the check", async () => {
  const {runtime} = await activatedRuntime();
  assert.equal(await runtime.verifyActivation(), "active");
  assert.notEqual(runtime.activeContext(), null);

  const keys = ed25519Keys();
  const fresh = service(new MemoryStore(), new GatewayFake(signedLicense(keys.privateKey, futureDate())), keys.publicKey);
  assert.equal(await fresh.verifyActivation(), "notActivated");
});

async function activatedRuntime() {
  const keys = ed25519Keys();
  const store = new MemoryStore();
  const gateway = new GatewayFake(signedLicense(keys.privateKey, futureDate()));
  const runtime = service(store, gateway, keys.publicKey);
  await runtime.activate({activationToken});
  return {runtime, store, gateway};
}

test("keeps an expired signed license locked after restart", async () => {
  const keys = ed25519Keys();
  const store = new MemoryStore();
  const gateway = new GatewayFake(signedLicense(keys.privateKey, "2026-09-09T11:00:00.000Z"));
  const activated = service(store, gateway, keys.publicKey, () => new Date("2026-09-09T10:00:00.000Z"));
  await activated.activate({activationToken});
  const restarted = service(store, gateway, keys.publicKey);

  assert.equal(await restarted.restore(), null);
  assert.deepEqual(restarted.status(), {
    state: "expired",
    expiresAt: "2026-09-09T11:00:00.000Z",
  });
});

test("rejects a signed license whose payload was changed", async () => {
  const keys = ed25519Keys();
  const license = signedLicense(keys.privateKey, futureDate());
  const gateway = new GatewayFake({
    ...license,
    payload: {...license.payload, workspaceId: "other-workspace"},
  });
  const runtime = service(new MemoryStore(), gateway, keys.publicKey);

  await assert.rejects(() => runtime.activate({activationToken}), /ungültig/);
});

function service(store: RuntimeLicenseStore, gateway: RuntimeLicenseGatewayClient, publicKey: string, clock: () => Date = now): GatewayRuntimeLicenseService {
  return new GatewayRuntimeLicenseService(store, gateway, publicKey, clock);
}

function signedLicense(privateKey: string, expiresAt: string): SignedRuntimeLicense {
  return signRuntimeLicense({
    licenseId: "license-1",
    licenseName: "Beispiel GmbH",
    activationId: "activation-1",
    workspaceId: "workspace-1",
    issuedAt: "2026-09-09T09:00:00.000Z",
    expiresAt,
  }, privateKey);
}

function futureDate(): string { return "2026-09-10T11:00:00.000Z"; }
function now(): Date { return new Date("2026-09-09T12:00:00.000Z"); }

function ed25519Keys(): {privateKey: string; publicKey: string} {
  const keys = generateKeyPairSync("ed25519");
  return {
    privateKey: String(keys.privateKey.export({format: "pem", type: "pkcs8"})),
    publicKey: String(keys.publicKey.export({format: "pem", type: "spki"})),
  };
}

class GatewayFake implements RuntimeLicenseGatewayClient {
  readonly tokens: string[] = [];
  readonly releases: RuntimeLicenseActivation[] = [];

  constructor(private readonly license: SignedRuntimeLicense) {}

  async activate(token: string) {
    this.tokens.push(token);
    return {license: this.license, activationSecret: "activation-secret"};
  }

  async release(activation: RuntimeLicenseActivation): Promise<void> {
    this.releases.push(activation);
  }

  verdict: RuntimeLicenseVerdict | Error = "active";
  async verify(): Promise<RuntimeLicenseVerdict> {
    if (this.verdict instanceof Error) throw this.verdict;
    return this.verdict;
  }
}

class MemoryStore implements RuntimeLicenseStore {
  state: RuntimeLicenseActivation | undefined;
  async load(): Promise<RuntimeLicenseActivation | null> { return this.state ?? null; }
  async save(state: RuntimeLicenseActivation): Promise<void> { this.state = state; }
  async clear(): Promise<void> { this.state = undefined; }
}
