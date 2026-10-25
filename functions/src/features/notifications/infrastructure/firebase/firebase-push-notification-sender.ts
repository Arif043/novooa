import {
  type BatchResponse,
  getMessaging,
  type MulticastMessage,
  type SendResponse,
} from "firebase-admin/messaging";
import {errorDetails, logError, logInfo} from "../../../../shared/logging/logger.js";
import {initializeAdminApp} from "../../../../shared/firebase/firestore-db.js";
import {type PushNotification} from
  "../../domain/entities/push-notification.js";
import {type PushNotificationSender} from
  "../../domain/repositories/push-notification-sender.js";

const maximumTokensPerRequest = 500;

export type FcmTokenDocument = {
  token: string;
  delete(): Promise<void>;
};

export interface FcmTokenStore {
  tokensForRecipient(recipientId: string): Promise<FcmTokenDocument[]>;
}

export interface FcmMessagingClient {
  send(message: MulticastMessage): Promise<BatchResponse>;
}

export class FirebasePushNotificationSender implements PushNotificationSender {
  constructor(
    private readonly tokenStore: FcmTokenStore,
    private readonly messagingClient: FcmMessagingClient = new FirebaseMessagingClient(),
  ) {}

  async sendToRecipient(
    recipientId: string,
    notification: PushNotification,
  ): Promise<void> {
    try {
      const tokenDocuments = uniqueTokenDocuments(
        await this.tokenStore.tokensForRecipient(recipientId),
      );
      for (const tokenBatch of tokenBatches(tokenDocuments)) {
        await this.sendTokenBatch(recipientId, tokenBatch, notification);
      }
    } catch (error) {
      logError("push_notification.failed", {recipientId, error: errorDetails(error)});
    }
  }

  private async sendTokenBatch(
    recipientId: string,
    tokenDocuments: FcmTokenDocument[],
    notification: PushNotification,
  ): Promise<void> {
    try {
      const response = await this.messagingClient.send(
        multicastMessage(tokenDocuments, notification),
      );
      await removeInvalidTokens(tokenDocuments, response.responses);
      logInfo("push_notification.sent", {
        recipientId, successCount: response.successCount, failureCount: response.failureCount,
      });
    } catch (error) {
      logError("push_notification.failed", {recipientId, error: errorDetails(error)});
    }
  }
}

class FirebaseMessagingClient implements FcmMessagingClient {
  async send(message: MulticastMessage): Promise<BatchResponse> {
    initializeAdminApp();
    return getMessaging().sendEachForMulticast(message);
  }
}

function tokenBatches(tokens: FcmTokenDocument[]): FcmTokenDocument[][] {
  const batches: FcmTokenDocument[][] = [];
  for (let index = 0; index < tokens.length; index += maximumTokensPerRequest) {
    batches.push(tokens.slice(index, index + maximumTokensPerRequest));
  }
  return batches;
}

function multicastMessage(
  tokens: FcmTokenDocument[],
  notification: PushNotification,
): MulticastMessage {
  return {
    tokens: tokens.map((document) => document.token),
    notification: {title: notification.title, body: notification.body},
    // Kein `fcmOptions.link`: Das Relay kennt die Adresse der Runtime nicht;
    // den Klick behandelt der Service Worker der Web-App selbst.
    data: notification.data,
  };
}

function uniqueTokenDocuments(
  tokenDocuments: FcmTokenDocument[],
): FcmTokenDocument[] {
  const knownTokens = new Set<string>();
  return tokenDocuments.filter((document) => {
    if (knownTokens.has(document.token)) return false;
    knownTokens.add(document.token);
    return true;
  });
}

async function removeInvalidTokens(
  tokens: FcmTokenDocument[],
  responses: SendResponse[],
): Promise<void> {
  const invalidTokens = tokens.filter((_, index) => isInvalidToken(responses[index]));
  await Promise.all(invalidTokens.map((document) => document.delete()));
}

function isInvalidToken(response: SendResponse | undefined): boolean {
  const code = response?.error?.code;
  return code === "messaging/invalid-registration-token" ||
    code === "messaging/registration-token-not-registered";
}
