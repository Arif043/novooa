import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type GoogleAccountSummary, type GoogleDriveItem} from "../../domain/entities/google-account.js";
import {GoogleReauthorizationRequiredError} from "../../domain/repositories/google-access-tokens.js";

export type RelayedGoogleAccessToken = {accessToken: string; expiresAt: Date};

export interface RuntimeGoogleRelayClient {
  beginAuthorization(license: SignedRuntimeLicense, loginHint?: string): Promise<{authorizationUrl: string}>;
  listAccounts(license: SignedRuntimeLicense): Promise<GoogleAccountSummary[]>;
  accessToken(license: SignedRuntimeLicense, accountId: string): Promise<RelayedGoogleAccessToken>;
}

export class HttpRuntimeGoogleRelayClient implements RuntimeGoogleRelayClient {
  private readonly endpoint: URL;

  constructor(endpoint: string, private readonly request: typeof fetch = fetch) {
    this.endpoint = new URL(endpoint);
    if (this.endpoint.protocol !== "https:") throw new Error("Das Google-Relay muss HTTPS verwenden.");
  }

  async beginAuthorization(license: SignedRuntimeLicense, loginHint?: string) {
    const body = await this.send({type: "beginAuthorization", license, loginHint});
    return {authorizationUrl: text(body.authorizationUrl, "authorizationUrl")};
  }

  async listAccounts(license: SignedRuntimeLicense) {
    const body = await this.send({type: "listAccounts", license});
    if (!Array.isArray(body.items)) throw new Error("Das Google-Relay hat ungültige Konten geliefert.");
    return body.items.map(accountFrom);
  }

  async accessToken(license: SignedRuntimeLicense, accountId: string) {
    const body = await this.send({type: "accessToken", license, accountId});
    const expiresAt = new Date(text(body.expiresAt, "expiresAt"));
    if (Number.isNaN(expiresAt.getTime())) throw new Error("expiresAt ist ungültig.");
    return {accessToken: text(body.accessToken, "accessToken"), expiresAt};
  }

  private async send(body: object): Promise<Record<string, unknown>> {
    const response = await this.request(this.endpoint, {
      method: "POST", headers: {"content-type": "application/json"},
      body: JSON.stringify(body), signal: AbortSignal.timeout(10_000),
    });
    if (response.status === 409) throw new GoogleReauthorizationRequiredError();
    if (!response.ok) throw new Error("Das Google-Relay hat die Anfrage abgelehnt.");
    return record(await response.json());
  }
}

export class UnavailableRuntimeGoogleRelayClient implements RuntimeGoogleRelayClient {
  async beginAuthorization(): Promise<{authorizationUrl: string}> { throw unavailable(); }
  async listAccounts(): Promise<GoogleAccountSummary[]> { throw unavailable(); }
  async accessToken(): Promise<RelayedGoogleAccessToken> { throw unavailable(); }
}

function accountFrom(value: unknown): GoogleAccountSummary {
  const entry = record(value);
  return {
    id: text(entry.id, "id"), email: text(entry.email, "email"),
    status: entry.status === "active" ? "active" : "reauthorizationRequired",
    sharedItems: Array.isArray(entry.sharedItems) ? entry.sharedItems.map(itemFrom) : [],
  };
}

function itemFrom(value: unknown): GoogleDriveItem {
  const entry = record(value);
  return {id: text(entry.id, "id"), name: text(entry.name, "name"), mimeType: text(entry.mimeType, "mimeType")};
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new Error("Die Antwort des Google-Relays ist ungültig.");
}

function text(value: unknown, name: string): string {
  if (typeof value !== "string" || value.trim().length === 0) throw new Error(`${name} ist ungültig.`);
  return value;
}

function unavailable(): Error {
  return new Error("Das novooa Google-Relay ist nicht konfiguriert.");
}
