import {ConnectionAuthError, type Connection} from "../../domain/entities/connection.js";

type CachedToken = {token: string; expiresAtMs: number};

const requestTimeoutMilliseconds = 15_000;
const safetyMarginMilliseconds = 60_000;
/** Ohne `expires_in` im Token-Ergebnis gilt das Token nur kurz. */
const defaultLifetimeSeconds = 300;

/**
 * Holt Zugriffstoken per OAuth „client credentials“ und hält sie im Speicher bis kurz vor Ablauf.
 * Der Zwischenspeicher-Schlüssel enthält `updatedAt`: Wird die Verbindung bearbeitet, gilt ein neues Token.
 */
export class OAuthTokenProvider {
  private readonly cache = new Map<string, CachedToken>();
  private readonly pending = new Map<string, Promise<string>>();

  constructor(
    private readonly request: typeof fetch = fetch,
    private readonly now: () => number = Date.now,
  ) {}

  async token(connection: Connection, clientSecret: string): Promise<string> {
    if (connection.auth.kind !== "oauthClientCredentials") throw new Error("Die Verbindung nutzt kein OAuth.");
    const key = `${connection.teamId}/${connection.id}/${connection.updatedAt}`;
    const cached = this.cache.get(key);
    if (cached !== undefined && cached.expiresAtMs - safetyMarginMilliseconds > this.now()) return cached.token;
    const running = this.pending.get(key);
    if (running !== undefined) return running;
    const fetched = this.fetchToken(connection, clientSecret, key).finally(() => this.pending.delete(key));
    this.pending.set(key, fetched);
    return fetched;
  }

  private async fetchToken(connection: Connection, clientSecret: string, key: string): Promise<string> {
    const auth = connection.auth;
    if (auth.kind !== "oauthClientCredentials") throw new Error("Die Verbindung nutzt kein OAuth.");
    const fields: Record<string, string> = {grant_type: "client_credentials", client_id: auth.clientId, client_secret: clientSecret};
    if (auth.scope !== undefined) fields.scope = auth.scope;
    const asJson = auth.tokenRequestFormat === "json";
    let response: Response;
    try {
      response = await this.request(auth.tokenUrl, {
        method: "POST",
        headers: {"content-type": asJson ? "application/json" : "application/x-www-form-urlencoded", accept: "application/json"},
        body: asJson ? JSON.stringify(fields) : new URLSearchParams(fields),
        signal: AbortSignal.timeout(requestTimeoutMilliseconds),
      });
    } catch {
      throw new ConnectionAuthError(`Die Anmeldung bei „${connection.name}“ ist fehlgeschlagen: Der Token-Server ist nicht erreichbar.`);
    }
    const body = await response.json().catch(() => ({})) as {access_token?: unknown; expires_in?: unknown; error_description?: unknown; error?: unknown};
    if (!response.ok || typeof body.access_token !== "string" || body.access_token.length === 0) {
      throw new ConnectionAuthError(`Die Anmeldung bei „${connection.name}“ ist fehlgeschlagen (Status ${response.status})${reasonOf(body)}.`);
    }
    const lifetime = typeof body.expires_in === "number" && body.expires_in > 0 ? body.expires_in : defaultLifetimeSeconds;
    this.cache.set(key, {token: body.access_token, expiresAtMs: this.now() + lifetime * 1000});
    return body.access_token;
  }
}

function reasonOf(body: {error_description?: unknown; error?: unknown}): string {
  const reason = typeof body.error_description === "string" ? body.error_description : typeof body.error === "string" ? body.error : "";
  return reason.length === 0 ? "" : `: ${reason.slice(0, 200)}`;
}
