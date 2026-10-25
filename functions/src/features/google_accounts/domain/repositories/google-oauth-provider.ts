import {type GoogleDriveItem} from "../entities/google-account.js";

export type GoogleAccessToken = {
  accessToken: string;
  expiresInSeconds: number;
};

export type GoogleTokenGrant = GoogleAccessToken & {
  /** Google liefert es nur, wenn die Einwilligung neu erteilt wurde (`prompt=consent`). */
  refreshToken?: string;
};

export type GoogleIdentity = {
  googleUserId: string;
  email: string;
};

/** Google hat die Anmeldung zurückgezogen (`invalid_grant`): nur erneutes Verbinden hilft. */
export class GoogleAuthorizationRevokedError extends Error {
  constructor(message = "Die Google-Anmeldung ist nicht mehr gültig.") {
    super(message);
    this.name = "GoogleAuthorizationRevokedError";
  }
}

export interface GoogleOAuthProvider {
  authorizationUrl(input: {state: string; codeChallenge: string; loginHint?: string}): string;
  exchangeCode(input: {code: string; codeVerifier: string}): Promise<GoogleTokenGrant>;
  refreshAccessToken(refreshToken: string): Promise<GoogleAccessToken>;
  loadIdentity(accessToken: string): Promise<GoogleIdentity>;
  /** Name und Typ freigegebener Einträge; was nicht (mehr) lesbar ist, fehlt im Ergebnis. */
  describeItems(input: {accessToken: string; ids: string[]}): Promise<GoogleDriveItem[]>;
}
