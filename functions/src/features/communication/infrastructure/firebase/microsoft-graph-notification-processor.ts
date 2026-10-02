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
  mailTokenService,
  microsoftGraphProvider,
} from "../microsoft_graph/microsoft-graph-config.js";
import {
  type MailConnectorTokenService,
  MailReauthorizationRequiredError,
} from "../../domain/services/mail-connector-token-service.js";
import {handleMailSubscriptionLifecycle} from "../../domain/usecases/handle-mail-subscription-lifecycle.js";
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
  const repository = new FirestoreMailConnectorRepository(mailConnectorCipher());
  const connection = await repository.loadConnectorBySubscription(notification.subscriptionId);
  if (!connection) return;
  const provider = microsoftGraphProvider();
  const tokens = mailTokenService(repository, provider);
  if (notification.lifecycleEvent) {
    return processLifecycle(notification, connection, {repository, provider, tokens});
  }
  if (notification.changeType !== "created" || !notification.messageId) return;
  if (connection.connector.status !== "active") return;
  await processNewMessage(notification, connection, tokens, provider);
}

type Connection = NonNullable<Awaited<ReturnType<FirestoreMailConnectorRepository["loadConnectorBySubscription"]>>>;

async function processLifecycle(
  notification: GraphNotification,
  connection: Connection,
  services: {repository: FirestoreMailConnectorRepository; provider: ReturnType<typeof microsoftGraphProvider>; tokens: MailConnectorTokenService},
): Promise<void> {
  const outcome = await handleMailSubscriptionLifecycle({
    event: notification.lifecycleEvent, ...connection, ...services,
  });
  logInfo("microsoft_graph.lifecycle_handled", {
    teamId: connection.connector.teamId, connectorId: connection.connector.id,
    event: notification.lifecycleEvent, outcome,
  });
}

async function processNewMessage(
  notification: GraphNotification,
  connection: Connection,
  tokens: MailConnectorTokenService,
  provider: ReturnType<typeof microsoftGraphProvider>,
): Promise<void> {
  try {
    const message = await tokens.withAccessToken(connection, (accessToken) =>
      provider.loadMessage({accessToken, messageId: notification.messageId}));
    await storeMessage(message, connection.connector, notification.messageId);
  } catch (error) {
    // Die Anmeldung ist ungültig (Status schon gesetzt) — Wiederholen der Aufgabe wäre sinnlos.
    if (!(error instanceof MailReauthorizationRequiredError)) throw error;
    logInfo("microsoft_graph.connector_needs_reauthorization", {
      teamId: connection.connector.teamId, connectorId: connection.connector.id,
    });
  }
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
