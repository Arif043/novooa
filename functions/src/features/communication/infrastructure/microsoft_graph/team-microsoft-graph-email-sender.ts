import {
  createOutboundMessage,
  markOutboundFailed,
  markOutboundSent,
} from "../firebase/send-channel-message-store.js";
import {sendMailConnectorMessage} from "../../domain/usecases/send-mail-connector-message.js";
import {FirestoreMailConnectorRepository} from "../firebase/firestore-mail-connector-repository.js";
import {microsoftGraphProvider} from "./microsoft-graph-config.js";

export async function sendTeamMicrosoftGraphEmail(input: {
  teamId: string;
  connectorId: string;
  recipient: string;
  subject: string;
  body: string;
  repository: FirestoreMailConnectorRepository;
}): Promise<{outboundId: string; providerMessageId: string; channelId: string}> {
  const channel = await channelFrom(input);
  const outboundInput = {channelId: channel.id, to: input.recipient, body: input.body};
  const outboundId = await createOutboundMessage({channel, recipient: input.recipient, input: outboundInput});
  try {
    await sendMailConnectorMessage({...input, repository: input.repository, provider: microsoftGraphProvider()});
    await markOutboundSent({channel, outboundId, sid: outboundId, recipient: input.recipient, input: outboundInput});
    return {outboundId, providerMessageId: outboundId, channelId: channel.id};
  } catch (error) {
    await markOutboundFailed({channel, outboundId, error});
    throw error;
  }
}

async function channelFrom(input: {
  teamId: string;
  connectorId: string;
  repository: FirestoreMailConnectorRepository;
}) {
  const connection = await input.repository.loadConnector(input);
  if (!connection || connection.connector.status !== "active") {
    throw new Error("Mail connector was not found or is inactive.");
  }
  return {
    id: connection.connector.id,
    teamId: connection.connector.teamId,
    kind: "email" as const,
    address: connection.connector.emailAddress,
    provider: "microsoftGraph" as const,
  };
}
