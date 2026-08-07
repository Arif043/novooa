import {timingSafeEqual} from "crypto";
import {type Request} from "express";
import {onRequest} from "firebase-functions/v2/https";
import {logException} from "../../../../shared/logging/logger.js";
import {FirestoreMailConnectorRepository} from
  "../firebase/firestore-mail-connector-repository.js";
import {dispatchMicrosoftGraphNotification} from
  "../firebase/microsoft-graph-notification-dispatcher.js";
import {
  mailConnectorCipher,
  mailConnectorEncryptionKey,
} from "../microsoft_graph/microsoft-graph-config.js";
import {type GraphNotification} from "./microsoft-graph-notification-processor.js";

export const microsoftGraphWebhook = onRequest(
  {invoker: "public", secrets: [mailConnectorEncryptionKey]},
  async (request, response) => {
    const validationToken = queryValue(request.query.validationToken);
    if (validationToken) return void response.status(200).type("text/plain").send(validationToken);
    if (request.method !== "POST") return void response.status(405).send("Method Not Allowed");
    try {
      await validateAndDispatch(request);
      response.status(202).send();
    } catch (error) {
      logException("microsoft_graph.webhook_failed", error);
      response.status(400).send("Invalid Microsoft Graph notification.");
    }
  },
);

async function validateAndDispatch(request: Request): Promise<void> {
  const repository = new FirestoreMailConnectorRepository(mailConnectorCipher());
  for (const notification of notificationsFrom(request.body)) {
    if (await isValidNotification(notification, repository)) {
      await dispatchMicrosoftGraphNotification(notification);
    }
  }
}

async function isValidNotification(
  notification: GraphNotification,
  repository: FirestoreMailConnectorRepository,
): Promise<boolean> {
  const connection = await repository.loadConnectorBySubscription(notification.subscriptionId);
  if (!connection) return false;
  if (!hasExpectedClientState(connection.credentials.subscriptionClientState, notification.clientState)) {
    throw new Error("Microsoft Graph client state does not match.");
  }
  return true;
}

function notificationsFrom(value: unknown): GraphNotification[] {
  if (!isRecord(value) || !Array.isArray(value.value)) throw new Error("Invalid notification payload.");
  return value.value.flatMap(notificationFrom);
}

function notificationFrom(value: unknown): GraphNotification[] {
  if (!isRecord(value)) return [];
  return [{
    subscriptionId: stringFrom(value.subscriptionId), clientState: stringFrom(value.clientState),
    changeType: stringFrom(value.changeType), lifecycleEvent: stringFrom(value.lifecycleEvent),
    messageId: messageIdFrom(value.resourceData),
  }];
}

function messageIdFrom(value: unknown): string {
  return isRecord(value) ? stringFrom(value.id) : "";
}

function hasExpectedClientState(expected: string, actual: string): boolean {
  const expectedValue = Buffer.from(expected);
  const actualValue = Buffer.from(actual);
  return expectedValue.length === actualValue.length && timingSafeEqual(expectedValue, actualValue);
}

function queryValue(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function stringFrom(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
