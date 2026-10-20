import assert from "node:assert/strict";
import test from "node:test";
import {type RuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimeRelayLicenseVerifier} from
  "../../../licensing/domain/repositories/runtime-relay-license-verifier.js";
import {type RuntimePushDevice} from "../../domain/entities/runtime-push.js";
import {type RuntimePushDeviceStore} from
  "../../domain/repositories/runtime-push-device-store.js";
import {type PushNotificationSender} from
  "../../domain/repositories/push-notification-sender.js";
import {RuntimePushRelay} from "../../domain/usecases/runtime-push-relay.js";

test("binds a registered FCM token to the verified local license", async () => {
  const devices = new DeviceStoreFake();
  const relay = new RuntimePushRelay(new LicenseVerifierFake(), devices, new SenderFake());

  await relay.register(signedLicense(), {token: "a".repeat(32), platform: "macos"});

  assert.deepEqual(devices.saved, [{license, device: {token: "a".repeat(32), platform: "macos"}}]);
});

test("sends a relay notification to all devices of the verified license", async () => {
  const sender = new SenderFake();
  const relay = new RuntimePushRelay(new LicenseVerifierFake(), new DeviceStoreFake(), sender);

  await relay.send(signedLicense(), {
    title: "Freigabe erforderlich",
    body: "Eine Aufgabe wartet.",
    data: {type: "taskRunApproval", runId: "run-1"},
  });

  assert.deepEqual(sender.sent, [{licenseId: license.licenseId, notification: {
    title: "Freigabe erforderlich",
    body: "Eine Aufgabe wartet.",
    data: {type: "taskRunApproval", runId: "run-1"},
  }}]);
});

const license: RuntimeLicense = {
  licenseId: "license-1",
  licenseName: "Beispiel GmbH",
  activationId: "activation-1",
  workspaceId: "workspace-1",
  issuedAt: "2026-09-13T10:00:00.000Z",
  expiresAt: "2026-12-31T23:59:59.000Z", maxUsers: 5,
};

function signedLicense() {
  return {payload: license, signature: "signature"};
}

class LicenseVerifierFake implements RuntimeRelayLicenseVerifier {
  async verify() {
    return license;
  }
}

class DeviceStoreFake implements RuntimePushDeviceStore {
  readonly saved: {license: RuntimeLicense; device: RuntimePushDevice}[] = [];

  async save(nextLicense: RuntimeLicense, device: RuntimePushDevice) {
    this.saved.push({license: nextLicense, device});
  }

  async remove(): Promise<void> {}
}

class SenderFake implements PushNotificationSender {
  readonly sent: {licenseId: string; notification: object}[] = [];

  async sendToRecipient(licenseId: string, notification: object) {
    this.sent.push({licenseId, notification});
  }
}
