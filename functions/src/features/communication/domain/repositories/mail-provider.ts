import {type ConnectorMailMessage} from "../entities/mail-message.js";
import {type MailConnectorProvider} from "../entities/mail-connector.js";

export type MailProviderAuthorization = {
  url: string;
};

export type MailProviderToken = {
  accessToken: string;
  refreshToken: string;
};

export type MailProviderProfile = {
  emailAddress: string;
  displayName: string;
};

export type MailProviderSubscription = {
  id: string;
  expiresAt: Date;
};

export interface MailProvider {
  readonly provider: MailConnectorProvider;

  authorizationUrl(input: {
    state: string;
    codeChallenge: string;
  }): MailProviderAuthorization;

  exchangeAuthorizationCode(input: {
    code: string;
    codeVerifier: string;
  }): Promise<MailProviderToken>;

  refreshAccessToken(refreshToken: string): Promise<MailProviderToken>;

  loadProfile(accessToken: string): Promise<MailProviderProfile>;

  createMessageSubscription(input: {
    accessToken: string;
    clientState: string;
  }): Promise<MailProviderSubscription>;

  renewMessageSubscription(input: {
    accessToken: string;
    subscriptionId: string;
  }): Promise<MailProviderSubscription>;

  loadMessage(input: {
    accessToken: string;
    messageId: string;
  }): Promise<ConnectorMailMessage>;

  sendMessage(input: {
    accessToken: string;
    recipient: string;
    subject: string;
    body: string;
  }): Promise<void>;
}
