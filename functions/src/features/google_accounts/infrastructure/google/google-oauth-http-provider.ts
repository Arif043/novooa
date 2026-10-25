import {type GoogleDriveItem} from "../../domain/entities/google-account.js";
import {
  GoogleAuthorizationRevokedError,
  type GoogleAccessToken,
  type GoogleIdentity,
  type GoogleOAuthProvider,
  type GoogleTokenGrant,
} from "../../domain/repositories/google-oauth-provider.js";

export type GoogleOAuthClient = {
  clientId: string;
  /** Leer, wenn nur die Anmelde-Adresse gebraucht wird. */
  clientSecret: string;
  redirectUri: string;
};

/** `drive.file`: nur selbst angelegte und im Picker freigegebene Dateien (keine Google-Verifizierung nötig). */
export const googleAccountScopes = ["openid", "email", "https://www.googleapis.com/auth/drive.file"];

const requestTimeoutMilliseconds = 15_000;

export class GoogleOAuthHttpProvider implements GoogleOAuthProvider {
  constructor(private readonly client: GoogleOAuthClient, private readonly request: typeof fetch = fetch) {}

  authorizationUrl(input: {state: string; codeChallenge: string; loginHint?: string}): string {
    const parameters = new URLSearchParams({
      client_id: this.client.clientId, redirect_uri: this.client.redirectUri, response_type: "code",
      scope: googleAccountScopes.join(" "), access_type: "offline", prompt: "consent",
      code_challenge: input.codeChallenge, code_challenge_method: "S256", state: input.state,
      // Google-Picker in der Anmeldung: Die gewählten Einträge kommen als `picked_file_ids` zurück.
      trigger_onepick: "true", allow_folder_selection: "true", allow_multiple: "true",
    });
    if (input.loginHint) parameters.set("login_hint", input.loginHint);
    return `https://accounts.google.com/o/oauth2/v2/auth?${parameters.toString()}`;
  }

  async exchangeCode(input: {code: string; codeVerifier: string}): Promise<GoogleTokenGrant> {
    const data = await this.token({
      grant_type: "authorization_code", code: input.code, code_verifier: input.codeVerifier,
      redirect_uri: this.client.redirectUri,
    });
    const refreshToken = typeof data.refresh_token === "string" ? data.refresh_token : undefined;
    return {...accessTokenFrom(data), refreshToken};
  }

  async refreshAccessToken(refreshToken: string): Promise<GoogleAccessToken> {
    return accessTokenFrom(await this.token({grant_type: "refresh_token", refresh_token: refreshToken}));
  }

  async loadIdentity(accessToken: string): Promise<GoogleIdentity> {
    const data = await this.json("https://openidconnect.googleapis.com/v1/userinfo", accessToken);
    if (typeof data.sub !== "string" || typeof data.email !== "string") throw new Error("Google hat kein Konto geliefert.");
    return {googleUserId: data.sub, email: data.email};
  }

  async describeItems(input: {accessToken: string; ids: string[]}): Promise<GoogleDriveItem[]> {
    const items = await Promise.all(input.ids.map((id) => this.describeItem(input.accessToken, id)));
    return items.filter((item): item is GoogleDriveItem => item !== null);
  }

  private async describeItem(accessToken: string, id: string): Promise<GoogleDriveItem | null> {
    const url = `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(id)}?fields=id,name,mimeType&supportsAllDrives=true`;
    const response = await this.send(url, {headers: {authorization: `Bearer ${accessToken}`}});
    if (response.status === 404) return null;
    const data = await bodyOf(response, "Drive");
    return {id: textOr(data.id, id), name: textOr(data.name, id), mimeType: textOr(data.mimeType, "application/octet-stream")};
  }

  private async token(fields: Record<string, string>): Promise<Record<string, unknown>> {
    const response = await this.send("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: {"content-type": "application/x-www-form-urlencoded"},
      body: new URLSearchParams({...fields, client_id: this.client.clientId, client_secret: this.client.clientSecret}),
    });
    const data = await response.json().catch(() => ({})) as Record<string, unknown>;
    if (response.ok) return data;
    if (data.error === "invalid_grant") throw new GoogleAuthorizationRevokedError();
    throw new Error(`Google-Token-Anfrage fehlgeschlagen (Status ${response.status}): ${textOr(data.error, "unbekannt")}.`);
  }

  private async json(url: string, accessToken: string): Promise<Record<string, unknown>> {
    return bodyOf(await this.send(url, {headers: {authorization: `Bearer ${accessToken}`}}), "Google");
  }

  private send(url: string, init: RequestInit): Promise<Response> {
    return this.request(url, {...init, signal: AbortSignal.timeout(requestTimeoutMilliseconds)});
  }
}

function accessTokenFrom(data: Record<string, unknown>): GoogleAccessToken {
  if (typeof data.access_token !== "string" || data.access_token.length === 0) throw new Error("Google hat kein Zugriffstoken geliefert.");
  const expiresIn = typeof data.expires_in === "number" && data.expires_in > 0 ? data.expires_in : 300;
  return {accessToken: data.access_token, expiresInSeconds: expiresIn};
}

function textOr(value: unknown, fallback: string): string {
  return typeof value === "string" ? value : fallback;
}

async function bodyOf(response: Response, service: string): Promise<Record<string, unknown>> {
  const data = await response.json().catch(() => ({})) as Record<string, unknown>;
  if (!response.ok) throw new Error(`${service}-Anfrage fehlgeschlagen (Status ${response.status}).`);
  return data;
}
