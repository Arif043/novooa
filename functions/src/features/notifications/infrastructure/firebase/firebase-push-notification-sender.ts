import {
  type BatchResponse,
  getMessaging,
  type MulticastMessage,
  type SendResponse,
} from "firebase-admin/messaging";
import {errorDetails, logError, logInfo} from "../../../../shared/logging/logger.js";
import {
  getDatabase,
  initializeAdminApp,
} from "../../../../shared/firebase/firestore-db.js";

const maximumTokensPerRequest = 500;
const webAppUrl = "https://syscat-90bff.web.app";

export type PushNotification = {
  title: string;
  body: string;
  data: Record<string, string>;
};

export type FcmTokenDocument = {
  token: string;
  delete(): Promise<void>;
};

export interface FcmTokenStore {
  tokensForUser(uid: string): Promise<FcmTokenDocument[]>;
}

export interface FcmMessagingClient {
  send(message: MulticastMessage): Promise<BatchResponse>;
}

export class FirebasePushNotificationSender {
  constructor(
    private readonly tokenStore: FcmTokenStore = new FirestoreFcmTokenStore(),
    private readonly messagingClient: FcmMessagingClient = new FirebaseMessagingClient(),
  ) {}

  async sendToUser(uid: string, notification: PushNotification): Promise<void> {
    try {
      const tokenDocuments = uniqueTokenDocuments(
        await this.tokenStore.tokensForUser(uid),
      );
      for (const tokenBatch of tokenBatches(tokenDocuments)) {
        await this.sendTokenBatch(uid, tokenBatch, notification);
      }
    } catch (error) {
      logError("push_notification.failed", {uid, error: errorDetails(error)});
    }
  }

  private async sendTokenBatch(
    uid: string,
    tokenDocuments: FcmTokenDocument[],
    notification: PushNotification,
  ): Promise<void> {
    try {
      const response = await this.messagingClient.send(
        multicastMessage(tokenDocuments, notification),
      );
      await removeInvalidTokens(tokenDocuments, response.responses);
      logInfo("push_notification.sent", {
        uid, successCount: response.successCount, failureCount: response.failureCount,
      });
    } catch (error) {
      logError("push_notification.failed", {uid, error: errorDetails(error)});
    }
  }
}

class FirestoreFcmTokenStore implements FcmTokenStore {
  async tokensForUser(uid: string): Promise<FcmTokenDocument[]> {
    const snapshots = await getDatabase().collection("users").doc(uid)
      .collection("fcmTokens").get();
    return snapshots.docs.flatMap((snapshot) => {
      const token = snapshot.data().token;
      return typeof token === "string" && token ? [{
        token,
        delete: async () => {
          await snapshot.ref.delete();
        },
      }] : [];
    });
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
    data: notification.data,
    webpush: {fcmOptions: {link: notificationUrl(notification.data)}},
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

function notificationUrl(data: Record<string, string>): string {
  const url = new URL("/activity", webAppUrl);
  const runId = data.runId;
  if (runId) url.searchParams.set("runId", runId);
  return url.toString();
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
