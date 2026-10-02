import {type ConnectorMailMessage} from "../entities/mail-message.js";
import {type MailConnectorProvider} from "../entities/mail-connector.js";

export type MailProviderAuthorization = {
  url: string;
};

export type MailProviderToken = {
  accessToken: string;
  refreshToken: string;
  /** Gültigkeit des Zugriffstokens ab Ausstellung; fehlt sie, gilt eine vorsichtige Standarddauer. */
  expiresInSeconds?: number;
};

/**
 * Die Anmeldung des Nutzers ist nicht mehr gültig (Passwortwechsel, widerrufene
 * Einwilligung, gesperrte App, abgelaufenes Refresh Token). Nur der Nutzer kann
 * das durch erneutes Verbinden beheben — Wiederholen hilft nicht.
 */
export class MailProviderAuthorizationError extends Error {
  constructor(message: string, readonly code: string) {
    super(message);
    this.name = "MailProviderAuthorizationError";
  }
}

/** Eine Anfrage an die API des Anbieters ist gescheitert; [status] erlaubt zwischen "nicht gefunden" und Störung zu unterscheiden. */
export class MailProviderRequestError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
    this.name = "MailProviderRequestError";
  }

  get isNotFound(): boolean {
    return this.status === 404;
  }
}

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
