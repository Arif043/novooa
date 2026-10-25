import {defineSecret, defineString} from "firebase-functions/params";
import {CredentialCipher} from "../../../../shared/security/credential-cipher.js";
import {GoogleOAuthHttpProvider} from "./google-oauth-http-provider.js";

export const googleOAuthClientId = defineString("GOOGLE_OAUTH_CLIENT_ID");
export const googleOAuthRedirectUri = defineString("GOOGLE_OAUTH_REDIRECT_URI");
export const googleOAuthClientSecret = defineSecret("GOOGLE_OAUTH_CLIENT_SECRET");
export const googleAccountEncryptionKey = defineSecret("GOOGLE_ACCOUNT_ENCRYPTION_KEY");

/** Nur für die Anmelde-Adresse: Dafür braucht es kein Client-Secret. */
export function googleAuthorizationProvider(): GoogleOAuthHttpProvider {
  return providerWith("");
}

export function googleOAuthProvider(): GoogleOAuthHttpProvider {
  return providerWith(googleOAuthClientSecret.value());
}

export function googleAccountCipher(): CredentialCipher {
  return new CredentialCipher(googleAccountEncryptionKey.value(), "GOOGLE_ACCOUNT_ENCRYPTION_KEY");
}

function providerWith(clientSecret: string): GoogleOAuthHttpProvider {
  return new GoogleOAuthHttpProvider({
    clientId: required(googleOAuthClientId.value(), "GOOGLE_OAUTH_CLIENT_ID"),
    clientSecret,
    redirectUri: required(googleOAuthRedirectUri.value(), "GOOGLE_OAUTH_REDIRECT_URI"),
  });
}

function required(value: string, name: string): string {
  const trimmed = value.trim();
  if (!trimmed) throw new Error(`${name} fehlt.`);
  return trimmed;
}
