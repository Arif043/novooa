import {
  type MailConnector,
  type MailConnectorCredentials,
} from "../entities/mail-connector.js";
import {type MailConnectorRepository} from "../repositories/mail-connector-repository.js";
import {type MailProvider} from "../repositories/mail-provider.js";

export async function renewMailConnectorSubscription(input: {
  connector: MailConnector;
  credentials: MailConnectorCredentials;
  repository: MailConnectorRepository;
  provider: MailProvider;
}): Promise<void> {
  if (!input.connector.subscriptionId) throw new Error("Mail connector has no subscription.");
  const token = await input.provider.refreshAccessToken(input.credentials.refreshToken);
  const subscription = await input.provider.renewMessageSubscription({
    accessToken: token.accessToken,
    subscriptionId: input.connector.subscriptionId,
  });
  await storeRenewedSubscription(input, token.refreshToken, subscription);
}

async function storeRenewedSubscription(
  input: Parameters<typeof renewMailConnectorSubscription>[0],
  refreshToken: string,
  subscription: {id: string; expiresAt: Date},
): Promise<void> {
  const {connector, credentials, repository} = input;
  await repository.updateCredentials({
    teamId: connector.teamId,
    connectorId: connector.id,
    credentials: {...credentials, refreshToken},
  });
  await repository.updateSubscription({
    teamId: connector.teamId,
    connectorId: connector.id,
    subscriptionId: subscription.id,
    subscriptionExpiresAt: subscription.expiresAt,
  });
}
