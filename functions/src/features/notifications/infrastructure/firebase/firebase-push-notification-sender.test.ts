import assert from "node:assert/strict";
import test from "node:test";
import {
  type BatchResponse,
  type MulticastMessage,
  type SendResponse,
} from "firebase-admin/messaging";
import {
  type FcmMessagingClient,
  type FcmTokenDocument,
  type FcmTokenStore,
  FirebasePushNotificationSender,
} from "./firebase-push-notification-sender.js";

class FakeTokenStore implements FcmTokenStore {
  constructor(private readonly tokens: FcmTokenDocument[]) {}

  async tokensForUser(): Promise<FcmTokenDocument[]> {
    return this.tokens;
  }
}

class FakeMessagingClient implements FcmMessagingClient {
  readonly messages: MulticastMessage[] = [];

  constructor(private readonly response: BatchResponse) {}

  async send(message: MulticastMessage): Promise<BatchResponse> {
    this.messages.push(message);
    return this.response;
  }
}

test("sendToUser sends a notification to every registered device", async () => {
  const messagingClient = new FakeMessagingClient(successfulBatch(2));
  const sender = new FirebasePushNotificationSender(
    new FakeTokenStore([token("phone").document, token("tablet").document]),
    messagingClient,
  );

  await sender.sendToUser("customer-1", notification());

  assert.deepEqual(messagingClient.messages, [{
    tokens: ["phone", "tablet"],
    notification: {title: "Freigabe erforderlich", body: "Bitte pruefen."},
    data: {runId: "run-1"},
    webpush: {
      fcmOptions: {link: "https://app.novooa.de"},
    },
  }]);
});

test("sendToUser sends an identical token only once", async () => {
  const messagingClient = new FakeMessagingClient(successfulBatch(1));
  const sender = new FirebasePushNotificationSender(
    new FakeTokenStore([token("phone").document, token("phone").document]),
    messagingClient,
  );

  await sender.sendToUser("customer-1", notification());

  assert.deepEqual(messagingClient.messages[0]?.tokens, ["phone"]);
});

test("sendToUser removes only invalid device tokens", async () => {
  const staleToken = token("stale");
  const validToken = token("valid");
  const messagingClient = new FakeMessagingClient({
    successCount: 1,
    failureCount: 1,
    responses: [invalidTokenResponse(), successfulResponse()],
  });
  const sender = new FirebasePushNotificationSender(
    new FakeTokenStore([staleToken.document, validToken.document]),
    messagingClient,
  );

  await sender.sendToUser("customer-1", notification());

  assert.equal(staleToken.deleted, true);
  assert.equal(validToken.deleted, false);
});

function token(value: string): TrackedToken {
  const trackedToken = {deleted: false};
  return {
    document: {
      token: value,
      async delete(): Promise<void> {
        trackedToken.deleted = true;
      },
    },
    get deleted(): boolean {
      return trackedToken.deleted;
    },
  };
}

function notification() {
  return {
    title: "Freigabe erforderlich",
    body: "Bitte pruefen.",
    data: {runId: "run-1"},
  };
}

function successfulBatch(count: number): BatchResponse {
  return {
    successCount: count,
    failureCount: 0,
    responses: Array.from({length: count}, () => successfulResponse()),
  };
}

type TrackedToken = {
  document: FcmTokenDocument;
  readonly deleted: boolean;
};

function successfulResponse(): SendResponse {
  return {success: true, messageId: "message-1"};
}

function invalidTokenResponse(): SendResponse {
  return {
    success: false,
    error: {code: "messaging/registration-token-not-registered"} as SendResponse["error"],
  };
}
