import assert from "node:assert/strict";
import test from "node:test";
import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {RuntimeMailRelay} from "./runtime-mail-relay.js";

test("scopes relay acknowledgement and rejection to the verified runtime license", async () => {
  const events = new EventStoreFake();
  const relay = new RuntimeMailRelay(new LicenseVerifierFake(), events, () => new Date("2026-09-21T12:00:00.000Z"));

  await relay.acknowledge({license: signedLicense(), eventId: "event-1", receipt: "receipt-1"});
  await relay.reject({
    license: signedLicense(), eventId: "event-2", receipt: "receipt-2", error: "Lokale Verarbeitung fehlgeschlagen.",
  });

  assert.deepEqual(events.acknowledgements, [{licenseId: "license-1", eventId: "event-1", receipt: "receipt-1"}]);
  assert.deepEqual(events.rejections, [{
    licenseId: "license-1", eventId: "event-2", receipt: "receipt-2",
    error: "Lokale Verarbeitung fehlgeschlagen.", now: new Date("2026-09-21T12:00:00.000Z"),
  }]);
});

test("replays dead letters only within the verified runtime license", async () => {
  const events = new EventStoreFake();
  const relay = new RuntimeMailRelay(new LicenseVerifierFake(), events, () => new Date("2026-09-21T12:00:00.000Z"));

  await relay.replay({license: signedLicense(), eventId: "dead-letter-1"});

  assert.deepEqual(events.replays, [{
    licenseId: "license-1", eventId: "dead-letter-1", now: new Date("2026-09-21T12:00:00.000Z"),
  }]);
});

class LicenseVerifierFake {
  async verify(license: SignedRuntimeLicense) {
    return license.payload;
  }
}

class EventStoreFake {
  acknowledgements: Array<{licenseId: string; eventId: string; receipt: string}> = [];
  rejections: Array<{licenseId: string; eventId: string; receipt: string; error: string; now: Date}> = [];
  replays: Array<{licenseId: string; eventId: string; now: Date}> = [];

  async enqueue(): Promise<void> {}
  async lease() { return []; }
  async acknowledge(input: {licenseId: string; eventId: string; receipt: string}) { this.acknowledgements.push(input); }
  async reject(input: {licenseId: string; eventId: string; receipt: string; error: string; now: Date}) { this.rejections.push(input); }
  async listDeadLetters() { return []; }
  async replay(input: {licenseId: string; eventId: string; now: Date}) { this.replays.push(input); }
}

function signedLicense(): SignedRuntimeLicense {
  return {
    signature: "signature",
    payload: {
      licenseId: "license-1", licenseName: "Kunde GmbH", activationId: "activation-1", workspaceId: "team-1",
      issuedAt: "2026-09-20T00:00:00.000Z", expiresAt: "2027-09-20T00:00:00.000Z",
    },
  };
}
