import assert from "node:assert/strict";
import test from "node:test";
import {RuntimeMailRelayWorker} from "./polling-runtime-mail-relay-worker.js";

test("acknowledges an event only after local processing succeeds", async () => {
  const relay = new RelayFake();
  const worker = new RuntimeMailRelayWorker(
    signedLicense,
    relay,
    {process: async () => undefined} as never,
    {exception: () => undefined} as never,
  );

  await worker.processOnce();

  assert.equal(relay.acknowledged, 1);
  assert.equal(relay.rejected, 0);
});

test("rejects a delivery when local processing fails", async () => {
  const relay = new RelayFake();
  const worker = new RuntimeMailRelayWorker(
    signedLicense,
    relay,
    {process: async () => { throw new Error("SQLite nicht verfügbar"); }} as never,
    {exception: () => undefined} as never,
  );

  await worker.processOnce();

  assert.equal(relay.acknowledged, 0);
  assert.equal(relay.rejected, 1);
});

class RelayFake {
  acknowledged = 0;
  rejected = 0;

  async pull() {
    return [{
      eventId: "event-1", connectorId: "connector-1", receipt: "receipt-1", attempt: 1,
      createdAt: "2026-09-21T12:00:00.000Z",
      event: {
        type: "emailReceived" as const, provider: "microsoftGraph" as const,
        providerMessageId: "message-1", receivedAt: "2026-09-21T12:00:00.000Z",
        senderEmail: "kunde@example.com", recipientEmail: "team@example.com",
        subject: "Frage", message: "Hallo", raw: {},
      },
    }];
  }

  async acknowledge() { this.acknowledged += 1; }
  async reject() { this.rejected += 1; }
  async beginMicrosoftAuthorization() { return {authorizationUrl: "https://example.test/authorize"}; }
  async sendEmail() { return {outboundId: "outbound-1", providerMessageId: "message-1", channelId: "connector-1"}; }
  async listDeadLetters() { return []; }
  async replayDeadLetter() {}
}

function signedLicense() {
  return {
    signature: "signature",
    payload: {
      licenseId: "license-1", licenseName: "Kunde GmbH", activationId: "activation-1", workspaceId: "team-1",
      issuedAt: "2026-09-20T00:00:00.000Z", expiresAt: "2027-09-20T00:00:00.000Z",
    },
  };
}
