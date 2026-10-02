import {type MailConnectorRepository} from "../repositories/mail-connector-repository.js";
import {type MailProvider} from "../repositories/mail-provider.js";
import {MailConnectorTokenService, MailReauthorizationRequiredError} from "../services/mail-connector-token-service.js";

export async function sendMailConnectorMessage(input: {
  teamId: string;
  connectorId: string;
  recipient: string;
  subject: string;
  body: string;
  repository: MailConnectorRepository;
  provider: MailProvider;
  /** Gemeinsamer Token-Dienst mit Cache; ohne Angabe nutzt der Aufruf einen eigenen. */
  tokens?: MailConnectorTokenService;
}): Promise<void> {
  const connection = await input.repository.loadConnector(input);
  if (connection?.connector.status === "reauthorizationRequired") {
    throw new MailReauthorizationRequiredError(input.connectorId);
  }
  if (!connection || connection.connector.status !== "active") {
    throw new Error("Mail connector was not found or is inactive.");
  }
  const tokens = input.tokens ?? new MailConnectorTokenService(input.repository, input.provider);
  await tokens.withAccessToken(connection, (accessToken) =>
    input.provider.sendMessage({
      accessToken,
      recipient: input.recipient,
      subject: input.subject,
      body: input.body,
    }));
}
