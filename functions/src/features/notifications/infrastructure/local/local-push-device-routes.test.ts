import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import assert from "node:assert/strict";
import test from "node:test";
import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {pushDeviceRoutes} from "./local-push-device-routes.js";
import {type RuntimePushRelayClient} from "./runtime-push-relay-client.js";

test("forwards a local FCM token with the signed license to the relay", async () => {
  const relay = new RelayFake();
  const handler = testingRoutes(pushDeviceRoutes, {signedLicense: () => license, relay: relay});

  const response = await handler.handle({
    method: "POST",
    url: "/v1/push-devices",
    body: {token: "a".repeat(32), platform: "macos"},
  });

  assert.deepEqual(response, {body: {status: "registered"}, statusCode: 200});
  assert.deepEqual(relay.devices, [{license, token: "a".repeat(32), platform: "macos"}]);
});

test("rejects push registration without a signed local license", async () => {
  const handler = testingRoutes(pushDeviceRoutes, {signedLicense: () => null, relay: new RelayFake()});

  const response = await handler.handle({
    method: "POST",
    url: "/v1/push-devices",
    body: {token: "a".repeat(32), platform: "macos"},
  });

  assert.equal(response?.statusCode, 400);
});

const license: SignedRuntimeLicense = {
  payload: {
    licenseId: "license-1",
    licenseName: "Beispiel GmbH",
    activationId: "activation-1",
    workspaceId: "workspace-1",
    issuedAt: "2026-09-13T10:00:00.000Z",
    expiresAt: "2026-12-31T23:59:59.000Z",
  },
  signature: "signature",
};

class RelayFake implements RuntimePushRelayClient {
  readonly devices: {license: SignedRuntimeLicense; token: string; platform: string}[] = [];

  async register(nextLicense: SignedRuntimeLicense, device: {token: string; platform: string}) {
    this.devices.push({license: nextLicense, ...device});
  }

  async remove(): Promise<void> {}
  async send(): Promise<void> {}
}
