import {type MailConnectorRepository} from "../repositories/mail-connector-repository.js";
import {type MailProvider} from "../repositories/mail-provider.js";

export async function sendMailConnectorMessage(input: {
  teamId: string;
  connectorId: string;
  recipient: string;
  subject: string;
  body: string;
  repository: MailConnectorRepository;
  provider: MailProvider;
}): Promise<void> {
  const connection = await input.repository.loadConnector(input);
  if (!connection || connection.connector.status !== "active") {
    throw new Error("Mail connector was not found or is inactive.");
  }
  const token = await input.provider.refreshAccessToken(connection.credentials.refreshToken);
  await sendMessage(input, token.accessToken);
  return storeRefreshToken(input, connection.credentials, token.refreshToken);
}

async function sendMessage(
  input: Parameters<typeof sendMailConnectorMessage>[0],
  accessToken: string,
): Promise<void> {
  await input.provider.sendMessage({
    accessToken,
    recipient: input.recipient,
    subject: input.subject,
    body: input.body,
  });
}

async function storeRefreshToken(
  input: Parameters<typeof sendMailConnectorMessage>[0],
  credentials: {refreshToken: string; subscriptionClientState: string},
  refreshToken: string,
): Promise<void> {
  await input.repository.updateCredentials({
    teamId: input.teamId,
    connectorId: input.connectorId,
    credentials: {...credentials, refreshToken},
  });
}
