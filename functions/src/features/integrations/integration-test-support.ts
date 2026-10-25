import {type GoogleAccessTokens} from "../google_accounts/domain/repositories/google-access-tokens.js";

/** Für Tests ohne Google-Bausteine: Jeder Zugriff wäre ein Fehler im Test. */
export const unusedGoogleTokens: GoogleAccessTokens = {
  token: () => Promise.reject(new Error("Im Test werden keine Google-Tokens gebraucht.")),
  invalidate: () => undefined,
};
