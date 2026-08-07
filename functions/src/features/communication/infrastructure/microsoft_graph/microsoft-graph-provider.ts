import {
  type ConnectorMailMessage,
} from "../../domain/entities/mail-message.js";
import {
  type MailProvider,
  type MailProviderAuthorization,
  type MailProviderProfile,
  type MailProviderSubscription,
  type MailProviderToken,
} from "../../domain/repositories/mail-provider.js";
import {graphJson, graphRequest, tokenFromForm} from "./microsoft-graph-http.js";
import {messageFrom, stringFrom} from "./microsoft-graph-mappers.js";

type MicrosoftGraphProviderConfig = {
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  notificationUrl: string;
};

export class MicrosoftGraphProvider implements MailProvider {
  constructor(config: MicrosoftGraphProviderConfig) {
    this.#config = config;
  }

  readonly provider = "microsoftGraph" as const;
  readonly #config: MicrosoftGraphProviderConfig;

  authorizationUrl(input: {
    state: string;
    codeChallenge: string;
  }): MailProviderAuthorization {
    const url = new URL("https://login.microsoftonline.com/common/oauth2/v2.0/authorize");
    url.search = authorizationParameters(this.#config, input).toString();
    return {url: url.toString()};
  }

  exchangeAuthorizationCode(input: {
    code: string;
    codeVerifier: string;
  }): Promise<MailProviderToken> {
    return tokenFromForm(tokenParameters(this.#config, input));
  }

  refreshAccessToken(refreshToken: string): Promise<MailProviderToken> {
    return tokenFromForm(refreshParameters(this.#config, refreshToken));
  }

  async loadProfile(accessToken: string): Promise<MailProviderProfile> {
    const profile = await graphJson("/v1.0/me?$select=displayName,mail,userPrincipalName", accessToken);
    const emailAddress = stringFrom(profile.mail) || stringFrom(profile.userPrincipalName);
    if (!emailAddress) throw new Error("Microsoft Graph did not return an email address.");
    return {emailAddress, displayName: stringFrom(profile.displayName) || emailAddress};
  }

  async createMessageSubscription(input: {
    accessToken: string;
    clientState: string;
  }): Promise<MailProviderSubscription> {
    const body = subscriptionDocument(this.#config.notificationUrl, input.clientState);
    const subscription = await graphJson("/v1.0/subscriptions", input.accessToken, body);
    return subscriptionFrom(subscription);
  }

  async renewMessageSubscription(input: {
    accessToken: string;
    subscriptionId: string;
  }): Promise<MailProviderSubscription> {
    const subscription = await graphJson(
      `/v1.0/subscriptions/${encodeURIComponent(input.subscriptionId)}`,
      input.accessToken,
      {expirationDateTime: subscriptionExpiration().toISOString()},
      undefined,
      "PATCH",
    );
    return subscriptionFrom(subscription);
  }

  async loadMessage(input: {
    accessToken: string;
    messageId: string;
  }): Promise<ConnectorMailMessage> {
    const message = await graphMessage(input.messageId, input.accessToken);
    return messageFrom(message);
  }

  async sendMessage(input: {
    accessToken: string;
    recipient: string;
    subject: string;
    body: string;
  }): Promise<void> {
    await graphRequest("/v1.0/me/sendMail", input.accessToken, sendMessageDocument(input));
  }
}

function authorizationParameters(
  config: MicrosoftGraphProviderConfig,
  input: {state: string; codeChallenge: string},
): URLSearchParams {
  return new URLSearchParams({
    client_id: config.clientId,
    response_type: "code",
    redirect_uri: config.redirectUri,
    response_mode: "query",
    scope: "offline_access Mail.Read Mail.Send User.Read",
    state: input.state,
    code_challenge: input.codeChallenge,
    code_challenge_method: "S256",
  });
}

function tokenParameters(
  config: MicrosoftGraphProviderConfig,
  input: {code: string; codeVerifier: string},
): URLSearchParams {
  return new URLSearchParams({
    client_id: config.clientId,
    client_secret: config.clientSecret,
    grant_type: "authorization_code",
    code: input.code,
    redirect_uri: config.redirectUri,
    code_verifier: input.codeVerifier,
  });
}

function refreshParameters(
  config: MicrosoftGraphProviderConfig,
  refreshToken: string,
): URLSearchParams {
  return new URLSearchParams({
    client_id: config.clientId,
    client_secret: config.clientSecret,
    grant_type: "refresh_token",
    refresh_token: refreshToken,
    scope: "offline_access Mail.Read Mail.Send User.Read",
  });
}

function subscriptionDocument(notificationUrl: string, clientState: string) {
  return {
    changeType: "created",
    notificationUrl,
    lifecycleNotificationUrl: notificationUrl,
    resource: "/me/messages",
    expirationDateTime: subscriptionExpiration().toISOString(),
    clientState,
  };
}

function subscriptionExpiration(): Date {
  return new Date(Date.now() + 2 * 24 * 60 * 60 * 1000);
}

function sendMessageDocument(input: {recipient: string; subject: string; body: string}) {
  return {
    message: {
      subject: input.subject,
      body: {contentType: "Text", content: input.body},
      toRecipients: [{emailAddress: {address: input.recipient}}],
    },
    saveToSentItems: true,
  };
}

async function graphMessage(messageId: string, accessToken: string): Promise<Record<string, unknown>> {
  const path = `/v1.0/me/messages/${encodeURIComponent(messageId)}?$select=id,from,toRecipients,subject,body,receivedDateTime`;
  return graphJson(path, accessToken, undefined, {Prefer: 'outlook.body-content-type="text"'});
}

function dateFrom(value: unknown): Date | null {
  if (typeof value !== "string") return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function subscriptionFrom(value: Record<string, unknown>): MailProviderSubscription {
  const id = stringFrom(value.id);
  const expiresAt = dateFrom(value.expirationDateTime);
  if (!id || !expiresAt) throw new Error("Microsoft Graph did not return a subscription.");
  return {id, expiresAt};
}
