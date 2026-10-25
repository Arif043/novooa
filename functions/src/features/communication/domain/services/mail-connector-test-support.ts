import {type MailConnector, type MailConnectorCredentials, type MailConnectorStatus} from "../entities/mail-connector.js";
import {type MailConnectorRepository} from "../repositories/mail-connector-repository.js";
import {
  MailProviderAuthorizationError,
  MailProviderRequestError,
  type MailProvider,
  type MailProviderSubscription,
  type MailProviderToken,
} from "../repositories/mail-provider.js";

/** Nur Tests: ein Speicher im Arbeitsspeicher mit protokollierten Änderungen. */
export class MemoryMailConnectorRepository {
  status: MailConnectorStatus;
  refreshToken: string;
  subscription: {id: string | null; expiresAt: Date | null};
  readonly statusChanges: MailConnectorStatus[] = [];
  readonly storedRefreshTokens: string[] = [];
  loads = 0;

  constructor(options: {status?: MailConnectorStatus; refreshToken?: string} = {}) {
    this.status = options.status ?? "active";
    this.refreshToken = options.refreshToken ?? "refresh-1";
    this.subscription = {id: "subscription-1", expiresAt: new Date(Date.now() + 3_600_000)};
  }

  async loadConnector() {
    this.loads++;
    return this.connection();
  }

  async updateCredentials(input: {credentials: MailConnectorCredentials}) {
    this.refreshToken = input.credentials.refreshToken;
    this.storedRefreshTokens.push(input.credentials.refreshToken);
  }

  async updateStatus(input: {status: MailConnectorStatus}) {
    this.status = input.status;
    this.statusChanges.push(input.status);
  }

  async updateSubscription(input: {subscriptionId: string; subscriptionExpiresAt: Date}) {
    this.subscription = {id: input.subscriptionId, expiresAt: input.subscriptionExpiresAt};
  }

  connection(): {connector: MailConnector; credentials: MailConnectorCredentials} {
    return {
      connector: {
        id: "connector-1", teamId: "team-1", createdByUid: "user-1", provider: "microsoftGraph",
        runtimeLicenseId: "lizenz-1", emailAddress: "team@example.com",
        displayName: "Team", status: this.status, subscriptionId: this.subscription.id,
        subscriptionExpiresAt: this.subscription.expiresAt, createdAt: new Date(), updatedAt: new Date(),
      },
      credentials: {refreshToken: this.refreshToken, subscriptionClientState: "client-state"},
    };
  }

  asRepository(): MailConnectorRepository {
    return this as unknown as MailConnectorRepository;
  }
}

export type RefreshScript = (refreshToken: string, call: number) => MailProviderToken | Error;

/** Nur Tests: ein Anbieter, dessen Antworten das Testszenario vorgibt. */
export class ScriptedMailProvider {
  readonly provider = "microsoftGraph" as const;
  refreshCalls: string[] = [];
  renewCalls: string[] = [];
  createCalls: string[] = [];
  sent: Array<Record<string, string>> = [];
  renewError: Error | null = null;
  sendFailures: Error[] = [];
  private accessCounter = 0;

  constructor(private readonly refreshScript: RefreshScript = (_token, call) => ({
    accessToken: `access-${call}`, refreshToken: `refresh-${call + 1}`, expiresInSeconds: 3600,
  })) {}

  async refreshAccessToken(refreshToken: string): Promise<MailProviderToken> {
    this.refreshCalls.push(refreshToken);
    const result = this.refreshScript(refreshToken, ++this.accessCounter);
    await Promise.resolve();
    if (result instanceof Error) throw result;
    return result;
  }

  async renewMessageSubscription(input: {accessToken: string; subscriptionId: string}): Promise<MailProviderSubscription> {
    this.renewCalls.push(`${input.accessToken}:${input.subscriptionId}`);
    if (this.renewError !== null) throw this.renewError;
    return {id: input.subscriptionId, expiresAt: new Date(Date.now() + 2 * 86_400_000)};
  }

  async createMessageSubscription(input: {accessToken: string; clientState: string}): Promise<MailProviderSubscription> {
    this.createCalls.push(`${input.accessToken}:${input.clientState}`);
    return {id: `new-subscription-${this.createCalls.length}`, expiresAt: new Date(Date.now() + 2 * 86_400_000)};
  }

  async sendMessage(input: Record<string, string>) {
    const failure = this.sendFailures.shift();
    if (failure !== undefined) throw failure;
    this.sent.push(input);
  }

  asProvider(): MailProvider {
    return this as unknown as MailProvider;
  }
}

export const invalidGrant = () => new MailProviderAuthorizationError("Microsoft token request failed: invalid_grant.", "invalid_grant");
export const serverError = () => new MailProviderRequestError("Microsoft token request failed: temporarily_unavailable.", 503);
export const notFound = () => new MailProviderRequestError("Microsoft Graph request failed: not found.", 404);
export const unauthorized = () => new MailProviderRequestError("Microsoft Graph request failed: expired.", 401);
