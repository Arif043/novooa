import {randomUUID} from "node:crypto";
import {MailReauthorizationRequiredError} from "../../domain/services/mail-connector-token-service.js";
import {sendMailConnectorMessage} from "../../domain/usecases/send-mail-connector-message.js";
import {FirestoreMailConnectorRepository} from "../firebase/firestore-mail-connector-repository.js";
import {mailTokenService, microsoftGraphProvider} from "./microsoft-graph-config.js";

/** Sendet eine E-Mail der Runtime über ihr verbundenes Postfach. */
export async function sendTeamMicrosoftGraphEmail(input: {
  teamId: string;
  connectorId: string;
  recipient: string;
  subject: string;
  body: string;
  repository: FirestoreMailConnectorRepository;
}): Promise<{outboundId: string; providerMessageId: string; channelId: string}> {
  await assertActiveConnector(input);
  const provider = microsoftGraphProvider();
  await sendMailConnectorMessage({
    ...input, provider, tokens: mailTokenService(input.repository, provider),
  });
  // Graph liefert für gesendete Mails keine ID; die Quittung braucht trotzdem eine.
  const outboundId = randomUUID();
  return {outboundId, providerMessageId: outboundId, channelId: input.connectorId};
}

async function assertActiveConnector(input: {
  teamId: string;
  connectorId: string;
  repository: FirestoreMailConnectorRepository;
}): Promise<void> {
  const connection = await input.repository.loadConnector(input);
  if (connection?.connector.status === "reauthorizationRequired") {
    throw new MailReauthorizationRequiredError(input.connectorId);
  }
  if (!connection || connection.connector.status !== "active") {
    throw new Error("Mail connector was not found or is inactive.");
  }
}
