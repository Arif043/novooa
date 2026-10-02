import {
  type MailConnector,
  type MailConnectorCredentials,
} from "../entities/mail-connector.js";
import {type MailConnectorRepository} from "../repositories/mail-connector-repository.js";
import {MailProviderRequestError, type MailProvider, type MailProviderSubscription} from "../repositories/mail-provider.js";
import {MailConnectorTokenService} from "../services/mail-connector-token-service.js";

export type SubscriptionInput = {
  connector: MailConnector;
  credentials: MailConnectorCredentials;
  repository: MailConnectorRepository;
  provider: MailProvider;
  /** Gemeinsamer Token-Dienst mit Cache; ohne Angabe nutzt der Aufruf einen eigenen. */
  tokens?: MailConnectorTokenService;
  now?: Date;
};

/**
 * Verlängert die Benachrichtigungs-Subscription. Gibt es sie nicht mehr — abgelaufen,
 * vom Anbieter entfernt oder nie angelegt —, wird eine neue angelegt, statt dauerhaft
 * an der Verlängerung zu scheitern. Eine ungültige Anmeldung wirft
 * `MailReauthorizationRequiredError` (der Status ist dann schon gesetzt).
 */
export async function renewMailConnectorSubscription(input: SubscriptionInput): Promise<"renewed" | "recreated"> {
  const tokens = tokensFor(input);
  const connection = {connector: input.connector, credentials: input.credentials};
  if (isLapsed(input)) return recreate(input, tokens, connection);
  try {
    const subscription = await tokens.withAccessToken(connection, (accessToken) =>
      input.provider.renewMessageSubscription({
        accessToken,
        subscriptionId: input.connector.subscriptionId as string,
      }));
    await storeSubscription(input, subscription);
    return "renewed";
  } catch (error) {
    if (!(error instanceof MailProviderRequestError) || !error.isNotFound) throw error;
    return recreate(input, tokens, connection);
  }
}

/** Legt unabhängig vom Zustand der alten Subscription eine neue an (nach `subscriptionRemoved`). */
export async function recreateMailConnectorSubscription(input: SubscriptionInput): Promise<"recreated"> {
  const connection = {connector: input.connector, credentials: input.credentials};
  return recreate(input, tokensFor(input), connection);
}

function tokensFor(input: SubscriptionInput): MailConnectorTokenService {
  return input.tokens ?? new MailConnectorTokenService(input.repository, input.provider);
}

function isLapsed(input: SubscriptionInput): boolean {
  const {subscriptionId, subscriptionExpiresAt} = input.connector;
  if (!subscriptionId) return true;
  return subscriptionExpiresAt !== null && subscriptionExpiresAt <= (input.now ?? new Date());
}

async function recreate(
  input: SubscriptionInput,
  tokens: MailConnectorTokenService,
  connection: {connector: MailConnector; credentials: MailConnectorCredentials},
): Promise<"recreated"> {
  const subscription = await tokens.withAccessToken(connection, (accessToken) =>
    input.provider.createMessageSubscription({
      accessToken,
      clientState: input.credentials.subscriptionClientState,
    }));
  await storeSubscription(input, subscription);
  return "recreated";
}

async function storeSubscription(input: SubscriptionInput, subscription: MailProviderSubscription): Promise<void> {
  await input.repository.updateSubscription({
    teamId: input.connector.teamId,
    connectorId: input.connector.id,
    subscriptionId: subscription.id,
    subscriptionExpiresAt: subscription.expiresAt,
  });
}
