import {type PluginAvailability} from "../plugins/domain/repositories/plugin-activation-store.js";
import {type GoogleAccessTokens} from "../google_accounts/domain/repositories/google-access-tokens.js";

/** Für Tests ohne Google-Bausteine: Jeder Zugriff wäre ein Fehler im Test. */
export const unusedGoogleTokens: GoogleAccessTokens = {
  token: () => Promise.reject(new Error("Im Test werden keine Google-Tokens gebraucht.")),
  invalidate: () => undefined,
};

/** Für Tests, die Plugins wie im aktivierten Arbeitsbereich ausführen. */
export const allPluginsEnabled: PluginAvailability = {isEnabled: async () => true};
