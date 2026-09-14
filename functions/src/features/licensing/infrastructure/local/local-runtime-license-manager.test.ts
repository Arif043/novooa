import assert from "node:assert/strict";
import {generateKeyPairSync} from "node:crypto";
import test from "node:test";
import {type SignedRuntimeLicense} from "../../domain/entities/runtime-license-lease.js";
import {signRuntimeLicense} from "../license-lease-crypto.js";
import {
  type RuntimeLicenseStore,
  type StoredRuntimeLicenseState,
} from "./file-local-runtime-license-store.js";
import {type RuntimeLicenseGatewayClient} from "./local-runtime-license-gateway-client.js";
import {GatewayRuntimeLicenseService} from "./local-runtime-license-manager.js";

const activationToken = "A3K9N7P2Q4R6";

test("activates independent local runtimes with the same customer token", async () => {
  const keys = ed25519Keys();
  const gateway = new GatewayFake(signedLicense(keys.privateKey, futureDate()));
  const firstStore = new MemoryStore();
  const first = service(firstStore, gateway, keys.publicKey);
  const second = service(new MemoryStore(), gateway, keys.publicKey);

  const firstContext = await first.activate({activationToken});
  const secondContext = await second.activate({activationToken});

  assert.equal(firstContext.workspaceId, "workspace-1");
  assert.deepEqual(secondContext, firstContext);
  assert.deepEqual(gateway.tokens, [activationToken, activationToken]);
  assert.doesNotMatch(JSON.stringify(firstStore.state), new RegExp(activationToken));
});

test("keeps an expired signed license locked after restart", async () => {
  const keys = ed25519Keys();
  const store = new MemoryStore();
  const gateway = new GatewayFake(
    signedLicense(keys.privateKey, "2026-09-09T11:00:00.000Z"),
  );
  const activated = service(
    store,
    gateway,
    keys.publicKey,
    () => new Date("2026-09-09T10:00:00.000Z"),
  );
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

  await assert.rejects(
    () => runtime.activate({activationToken}),
    /ungültig/,
  );
});

function service(
  store: RuntimeLicenseStore,
  gateway: RuntimeLicenseGatewayClient,
  publicKey: string,
  clock: () => Date = now,
): GatewayRuntimeLicenseService {
  return new GatewayRuntimeLicenseService(store, gateway, publicKey, clock);
}

function signedLicense(
  privateKey: string,
  expiresAt: string,
): SignedRuntimeLicense {
  return signRuntimeLicense({
    licenseId: "license-1",
    workspaceId: "workspace-1",
    issuedAt: "2026-09-09T09:00:00.000Z",
    expiresAt,
  }, privateKey);
}

function futureDate(): string {
  return "2026-09-10T11:00:00.000Z";
}

function now(): Date {
  return new Date("2026-09-09T12:00:00.000Z");
}

function ed25519Keys(): {privateKey: string; publicKey: string} {
  const keys = generateKeyPairSync("ed25519");
  return {
    privateKey: String(keys.privateKey.export({format: "pem", type: "pkcs8"})),
    publicKey: String(keys.publicKey.export({format: "pem", type: "spki"})),
  };
}

class GatewayFake implements RuntimeLicenseGatewayClient {
  readonly tokens: string[] = [];

  constructor(private readonly license: SignedRuntimeLicense) {}

  async requestLicense(token: string): Promise<SignedRuntimeLicense> {
    this.tokens.push(token);
    return this.license;
  }
}

class MemoryStore implements RuntimeLicenseStore {
  state: StoredRuntimeLicenseState | undefined;

  async load(): Promise<StoredRuntimeLicenseState | null> {
    return this.state ?? null;
  }

  async save(state: StoredRuntimeLicenseState): Promise<void> {
    this.state = state;
  }
}
