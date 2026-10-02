import {type MailConnector, type MailConnectorCredentials} from "../entities/mail-connector.js";
import {type MailConnectorRepository} from "../repositories/mail-connector-repository.js";
import {MailProviderAuthorizationError, MailProviderRequestError, type MailProvider} from "../repositories/mail-provider.js";
import {AccessTokenCache} from "./access-token-cache.js";

/** Der Connector braucht eine neue Anmeldung; sein Status steht dann auf `reauthorizationRequired`. */
export class MailReauthorizationRequiredError extends Error {
  constructor(readonly connectorId: string) {
    super("Der Mail-Connector muss neu verbunden werden.");
    this.name = "MailReauthorizationRequiredError";
  }
}

export type MailConnection = {connector: MailConnector; credentials: MailConnectorCredentials};

const defaultLifetimeSeconds = 45 * 60;

/**
 * Liefert gültige Zugriffstokens für einen Connector und kümmert sich um das
 * Refresh Token:
 *
 * - **Cache:** ein noch gültiges Zugriffstoken wird wiederverwendet.
 * - **Gleichzeitige Aufrufe** desselben Connectors teilen sich einen Refresh.
 * - **Rotation:** das vom Anbieter zurückgegebene neue Refresh Token wird gespeichert.
 * - **Wettlauf zwischen Instanzen:** Lehnt der Anbieter das Token ab, wird das
 *   gespeicherte neu geladen. Hat eine andere Instanz es inzwischen rotiert,
 *   wird mit dem neuen Token genau einmal wiederholt.
 * - **Ungültige Anmeldung:** Scheitert auch das, setzt der Dienst den Connector
 *   auf `reauthorizationRequired`, damit der Nutzer es sieht, und wirft
 *   [MailReauthorizationRequiredError].
 * - **Vorübergehende Fehler** (Netz, Serverfehler) laufen unverändert durch und
 *   ändern den Status nicht.
 */
export class MailConnectorTokenService {
  private readonly inflight = new Map<string, Promise<string>>();

  constructor(
    private readonly repository: MailConnectorRepository,
    private readonly provider: MailProvider,
    private readonly cache: AccessTokenCache = new AccessTokenCache(),
    private readonly now: () => number = Date.now,
  ) {}

  accessTokenFor(connection: MailConnection): Promise<string> {
    const cached = this.cache.get(connection.connector.id, this.now());
    if (cached !== null) return Promise.resolve(cached);
    const running = this.inflight.get(connection.connector.id);
    if (running !== undefined) return running;
    const refresh = this.refresh(connection).finally(() => this.inflight.delete(connection.connector.id));
    this.inflight.set(connection.connector.id, refresh);
    return refresh;
  }

  /**
   * Führt [operation] mit einem gültigen Zugriffstoken aus. Lehnt der Anbieter das
   * (gemerkte) Token mit 401 ab, wird genau einmal mit einem frischen wiederholt.
   */
  async withAccessToken<T>(
    connection: MailConnection,
    operation: (accessToken: string) => Promise<T>,
  ): Promise<T> {
    try {
      return await operation(await this.accessTokenFor(connection));
    } catch (error) {
      if (!(error instanceof MailProviderRequestError) || error.status !== 401) throw error;
      this.forget(connection.connector.id);
      return operation(await this.accessTokenFor(connection));
    }
  }

  /** Verwirft das gemerkte Zugriffstoken, etwa nachdem der Anbieter es abgelehnt hat. */
  forget(connectorId: string): void {
    this.cache.delete(connectorId);
  }

  private async refresh(connection: MailConnection): Promise<string> {
    try {
      return await this.refreshWith(connection, connection.credentials);
    } catch (error) {
      if (!(error instanceof MailProviderAuthorizationError)) throw error;
      return this.retryWithStoredCredentials(connection, error);
    }
  }

  private async retryWithStoredCredentials(
    connection: MailConnection,
    cause: MailProviderAuthorizationError,
  ): Promise<string> {
    const stored = await this.repository.loadConnector({
      teamId: connection.connector.teamId,
      connectorId: connection.connector.id,
    });
    const rotated = stored !== null && stored.credentials.refreshToken !== connection.credentials.refreshToken;
    if (rotated) {
      try {
        return await this.refreshWith(connection, stored.credentials);
      } catch (error) {
        if (!(error instanceof MailProviderAuthorizationError)) throw error;
      }
    }
    return this.requireReauthorization(connection, cause);
  }

  private async refreshWith(connection: MailConnection, credentials: MailConnectorCredentials): Promise<string> {
    const token = await this.provider.refreshAccessToken(credentials.refreshToken);
    await this.repository.updateCredentials({
      teamId: connection.connector.teamId,
      connectorId: connection.connector.id,
      credentials: {...credentials, refreshToken: token.refreshToken},
    });
    const lifetimeMilliseconds = (token.expiresInSeconds ?? defaultLifetimeSeconds) * 1000;
    this.cache.set(connection.connector.id, token.accessToken, this.now() + lifetimeMilliseconds);
    return token.accessToken;
  }

  private async requireReauthorization(
    connection: MailConnection,
    cause: MailProviderAuthorizationError,
  ): Promise<never> {
    this.cache.delete(connection.connector.id);
    await this.repository.updateStatus({
      teamId: connection.connector.teamId,
      connectorId: connection.connector.id,
      status: "reauthorizationRequired",
    });
    throw Object.assign(new MailReauthorizationRequiredError(connection.connector.id), {cause});
  }
}
