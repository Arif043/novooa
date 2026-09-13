import assert from "node:assert/strict";
import test from "node:test";
import {type LocalRuntimeLicense} from
  "../../../licensing/domain/entities/local-runtime-license-lease.js";
import {type LocalRuntimeRelayLicenseVerifier} from
  "../../../licensing/domain/repositories/local-runtime-relay-license-verifier.js";
import {type LocalRuntimePushDevice} from "../../domain/entities/local-runtime-push.js";
import {type LocalRuntimePushDeviceStore} from
  "../../domain/repositories/local-runtime-push-device-store.js";
import {type PushNotificationSender} from
  "../../domain/repositories/push-notification-sender.js";
import {LocalRuntimePushRelay} from "../../domain/usecases/local-runtime-push-relay.js";

test("binds a registered FCM token to the verified local license", async () => {
  const devices = new DeviceStoreFake();
  const relay = new LocalRuntimePushRelay(new LicenseVerifierFake(), devices, new SenderFake());

  await relay.register(signedLicense(), {token: "a".repeat(32), platform: "macos"});

  assert.deepEqual(devices.saved, [{license, device: {token: "a".repeat(32), platform: "macos"}}]);
});

test("sends a relay notification to all devices of the verified license", async () => {
  const sender = new SenderFake();
  const relay = new LocalRuntimePushRelay(new LicenseVerifierFake(), new DeviceStoreFake(), sender);

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

const license: LocalRuntimeLicense = {
  licenseId: "license-1",
  workspaceId: "workspace-1",
  issuedAt: "2026-09-13T10:00:00.000Z",
};

function signedLicense() {
  return {payload: license, signature: "signature"};
}

class LicenseVerifierFake implements LocalRuntimeRelayLicenseVerifier {
  async verify() {
    return license;
  }
}

class DeviceStoreFake implements LocalRuntimePushDeviceStore {
  readonly saved: {license: LocalRuntimeLicense; device: LocalRuntimePushDevice}[] = [];

  async save(nextLicense: LocalRuntimeLicense, device: LocalRuntimePushDevice) {
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
