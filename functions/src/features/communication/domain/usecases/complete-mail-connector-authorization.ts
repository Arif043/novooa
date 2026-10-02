import {
  type MailConnector,
  type MailConnectorCredentials,
} from "../entities/mail-connector.js";
import {type MailConnectorRepository} from
  "../repositories/mail-connector-repository.js";
import {type MailProvider} from "../repositories/mail-provider.js";

export async function completeMailConnectorAuthorization(input: {
  authorizationId: string;
  authorizationCode: string;
  connectorId: string;
  subscriptionClientState: string;
  repository: MailConnectorRepository;
  provider: MailProvider;
  now: Date;
}): Promise<MailConnector> {
  const authorization = await input.repository.consumeAuthorization(input.authorizationId);
  if (!authorization || authorization.provider !== input.provider.provider) {
    throw new Error("The mail connector authorization is invalid or expired.");
  }
  const token = await input.provider.exchangeAuthorizationCode({
    code: input.authorizationCode,
    codeVerifier: authorization.codeVerifier,
  });
  return createConnector(input, authorization, token);
}

async function createConnector(
  input: Parameters<typeof completeMailConnectorAuthorization>[0],
  authorization: Awaited<ReturnType<MailConnectorRepository["consumeAuthorization"]>> & {},
  token: {accessToken: string; refreshToken: string},
): Promise<MailConnector> {
  if (authorization === null) throw new Error("The mail connector authorization is invalid or expired.");
  const profile = await input.provider.loadProfile(token.accessToken);
  const subscription = await input.provider.createMessageSubscription({
    accessToken: token.accessToken,
    clientState: input.subscriptionClientState,
  });
  const existing = await input.repository.findConnectorByEmailAddress({
    teamId: authorization.teamId,
    emailAddress: profile.emailAddress,
  });
  const connector = connectorFrom(input, authorization, profile, subscription, existing);
  await input.repository.createConnector({connector, credentials: credentialsFrom(token, input)});
  return connector;
}

function connectorFrom(
  input: Parameters<typeof completeMailConnectorAuthorization>[0],
  authorization: NonNullable<Awaited<ReturnType<MailConnectorRepository["consumeAuthorization"]>>>,
  profile: {emailAddress: string; displayName: string},
  subscription: {id: string; expiresAt: Date},
  existing: MailConnector | null,
): MailConnector {
  // Wer ein Postfach erneut verbindet, behält die ID des Connectors: Verweise darauf
  // (Kanäle, Auslöser) bleiben gültig, statt ins Leere zu laufen.
  return {
    id: existing?.id ?? input.connectorId, teamId: authorization.teamId,
    createdByUid: existing?.createdByUid ?? authorization.uid, provider: input.provider.provider,
    deliveryTarget: authorization.deliveryTarget,
    runtimeLicenseId: authorization.runtimeLicenseId,
    emailAddress: profile.emailAddress, displayName: profile.displayName, status: "active",
    subscriptionId: subscription.id, subscriptionExpiresAt: subscription.expiresAt,
    createdAt: existing?.createdAt ?? input.now, updatedAt: input.now,
  };
}

function credentialsFrom(
  token: {refreshToken: string},
  input: Parameters<typeof completeMailConnectorAuthorization>[0],
): MailConnectorCredentials {
  return {refreshToken: token.refreshToken, subscriptionClientState: input.subscriptionClientState};
}
