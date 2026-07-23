import {type DocumentReference} from "firebase-admin/firestore";
import {
  getMessaging,
  type MulticastMessage,
  type SendResponse,
} from "firebase-admin/messaging";
import {errorDetails, logError, logInfo} from "../../task-runner/structured-logger.js";
import {getDatabase, initializeAdminApp} from "./firestore-db.js";

const maximumTokensPerRequest = 500;

export type PushNotification = {
  title: string;
  body: string;
  data: Record<string, string>;
};

type FcmTokenDocument = {
  token: string;
  reference: DocumentReference;
};

export class FirebasePushNotificationSender {
  async sendToUser(uid: string, notification: PushNotification): Promise<void> {
    try {
      const tokenDocuments = await fcmTokenDocuments(uid);
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
      initializeAdminApp();
      const response = await getMessaging().sendEachForMulticast(
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

async function fcmTokenDocuments(uid: string): Promise<FcmTokenDocument[]> {
  const snapshots = await getDatabase().collection("users").doc(uid)
    .collection("fcmTokens").get();
  return snapshots.docs.flatMap((snapshot) => {
    const token = snapshot.data().token;
    return typeof token === "string" && token ? [{token, reference: snapshot.ref}] : [];
  });
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
  return {tokens: tokens.map((document) => document.token), notification, data: notification.data};
}

async function removeInvalidTokens(
  tokens: FcmTokenDocument[],
  responses: SendResponse[],
): Promise<void> {
  const invalidTokens = tokens.filter((_, index) => isInvalidToken(responses[index]));
  await Promise.all(invalidTokens.map((document) => document.reference.delete()));
}

function isInvalidToken(response: SendResponse | undefined): boolean {
  const code = response?.error?.code;
  return code === "messaging/invalid-registration-token" ||
    code === "messaging/registration-token-not-registered";
}
