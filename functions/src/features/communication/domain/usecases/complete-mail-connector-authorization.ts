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
  return createConnector(input, authorization.teamId, authorization.uid, token);
}

async function createConnector(
  input: Parameters<typeof completeMailConnectorAuthorization>[0],
  teamId: string,
  uid: string,
  token: {accessToken: string; refreshToken: string},
): Promise<MailConnector> {
  const profile = await input.provider.loadProfile(token.accessToken);
  const subscription = await input.provider.createMessageSubscription({
    accessToken: token.accessToken,
    clientState: input.subscriptionClientState,
  });
  const connector = connectorFrom(input, teamId, uid, profile, subscription);
  await input.repository.createConnector({connector, credentials: credentialsFrom(token, input)});
  return connector;
}

function connectorFrom(
  input: Parameters<typeof completeMailConnectorAuthorization>[0],
  teamId: string,
  uid: string,
  profile: {emailAddress: string; displayName: string},
  subscription: {id: string; expiresAt: Date},
): MailConnector {
  return {
    id: input.connectorId, teamId, createdByUid: uid, provider: input.provider.provider,
    emailAddress: profile.emailAddress, displayName: profile.displayName, status: "active",
    subscriptionId: subscription.id, subscriptionExpiresAt: subscription.expiresAt,
    createdAt: input.now, updatedAt: input.now,
  };
}

function credentialsFrom(
  token: {refreshToken: string},
  input: Parameters<typeof completeMailConnectorAuthorization>[0],
): MailConnectorCredentials {
  return {refreshToken: token.refreshToken, subscriptionClientState: input.subscriptionClientState};
}
