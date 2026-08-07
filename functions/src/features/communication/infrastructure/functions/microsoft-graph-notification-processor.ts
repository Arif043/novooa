import {type ChannelMessageEvent} from
  "../../domain/entities/channel-message-event.js";
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
  connector: {id: string; teamId: string; emailAddress: string},
  messageId: string,
): Promise<void> {
  const event = eventFrom(message, connector.id);
  const channel = channelFrom(connector);
  const created = await storeInboundChannelMessage({channel, event});
  if (created) await dispatchChannelMessageTriggers({teamId: channel.teamId, channelId: channel.id, event});
  logInfo("microsoft_graph.message_received", {teamId: channel.teamId, connectorId: channel.id, messageId, created});
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
