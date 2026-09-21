import {type ChannelMessageEvent} from
  "../../domain/entities/channel-message-event.js";
import {createHash} from "node:crypto";
import {
  storeInboundChannelMessage,
  type CommunicationChannel,
} from "../firebase/channel-message-store.js";
import {dispatchChannelMessageTriggers} from
  "./channel-trigger-dispatcher.js";
import {logInfo} from "../../../../shared/logging/logger.js";
import {FirestoreMailConnectorRepository} from
  "../firebase/firestore-mail-connector-repository.js";
import {
  mailConnectorCipher,
  microsoftGraphProvider,
} from "../microsoft_graph/microsoft-graph-config.js";
import {FirestoreRuntimeMailRelayEventStore} from
  "./firestore-runtime-mail-relay-event-store.js";

export type GraphNotification = {
  subscriptionId: string;
  clientState: string;
  changeType: string;
  lifecycleEvent: string;
  messageId: string;
};

export async function processMicrosoftGraphNotification(
  notification: GraphNotification,
): Promise<void> {
  if (notification.lifecycleEvent || notification.changeType !== "created") return;
  const repository = new FirestoreMailConnectorRepository(mailConnectorCipher());
  const connection = await repository.loadConnectorBySubscription(notification.subscriptionId);
  if (!connection || !notification.messageId) return;
  const provider = microsoftGraphProvider();
  const accessToken = await refreshToken(connection, repository, provider);
  const message = await provider.loadMessage({accessToken, messageId: notification.messageId});
  await storeMessage(message, connection.connector, notification.messageId);
}

async function refreshToken(
  connection: NonNullable<Awaited<ReturnType<FirestoreMailConnectorRepository["loadConnectorBySubscription"]>>>,
  repository: FirestoreMailConnectorRepository,
  provider: ReturnType<typeof microsoftGraphProvider>,
): Promise<string> {
  const token = await provider.refreshAccessToken(connection.credentials.refreshToken);
  await repository.updateCredentials({
    teamId: connection.connector.teamId,
    connectorId: connection.connector.id,
    credentials: {...connection.credentials, refreshToken: token.refreshToken},
  });
  return token.accessToken;
}

async function storeMessage(
  message: {id: string; senderEmail: string; recipientEmail: string; subject: string; body: string; receivedAt: Date},
  connector: {
    id: string;
    teamId: string;
    emailAddress: string;
    deliveryTarget: "cloud" | "localRuntime";
    runtimeLicenseId: string | null;
  },
  messageId: string,
): Promise<void> {
  const event = eventFrom(message, connector.id);
  if (connector.deliveryTarget === "localRuntime") {
    await queueForLocalRuntime(connector, event);
    logInfo("microsoft_graph.message_queued_for_local_runtime", {
      teamId: connector.teamId, connectorId: connector.id, messageId,
    });
    return;
  }
  const channel = channelFrom(connector);
  const created = await storeInboundChannelMessage({channel, event});
  if (created) await dispatchChannelMessageTriggers({teamId: channel.teamId, channelId: channel.id, event});
  logInfo("microsoft_graph.message_received", {teamId: channel.teamId, connectorId: channel.id, messageId, created});
}

async function queueForLocalRuntime(
  connector: {id: string; teamId: string; runtimeLicenseId: string | null},
  event: ChannelMessageEvent,
): Promise<void> {
  if (!connector.runtimeLicenseId || event.type !== "emailReceived") {
    throw new Error("Der lokale Mail-Connector hat keine Runtime-Lizenz.");
  }
  await new FirestoreRuntimeMailRelayEventStore().enqueue({
    licenseId: connector.runtimeLicenseId, workspaceId: connector.teamId,
    event: {
      eventId: relayEventId(connector.runtimeLicenseId, event.providerMessageId),
      connectorId: connector.id, event, createdAt: event.receivedAt,
    },
  });
}

function eventFrom(
  message: {id: string; senderEmail: string; recipientEmail: string; subject: string; body: string; receivedAt: Date},
  connectorId: string,
): ChannelMessageEvent {
  return {
    type: "emailReceived", provider: "microsoftGraph", connectorId, providerMessageId: message.id,
    senderEmail: message.senderEmail, recipientEmail: message.recipientEmail,
    subject: message.subject, message: message.body, receivedAt: message.receivedAt.toISOString(),
    raw: {source: "microsoft_graph"},
  };
}

function channelFrom(connector: {id: string; teamId: string; emailAddress: string}): CommunicationChannel {
  return {id: connector.id, teamId: connector.teamId, kind: "email", address: connector.emailAddress};
}

function relayEventId(licenseId: string, providerMessageId: string): string {
  return createHash("sha256").update(`${licenseId}:${providerMessageId}`).digest("base64url");
}
