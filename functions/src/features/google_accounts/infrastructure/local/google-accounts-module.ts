import {RelayListCache} from "../../../../shared/local/relay-list-cache.js";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type GoogleAccountSummary} from "../../domain/entities/google-account.js";
import {type GoogleAccessTokens} from "../../domain/repositories/google-access-tokens.js";
import {RelayGoogleAccessTokens} from "./relay-google-access-tokens.js";
import {
  HttpRuntimeGoogleRelayClient,
  type RuntimeGoogleRelayClient,
  UnavailableRuntimeGoogleRelayClient,
} from "./runtime-google-relay-client.js";

/** Was die Runtime für Google-Konten prozessweit hält; überdauert einen Arbeitsbereichswechsel. */
export type GoogleAccountsModule = {
  relay: RuntimeGoogleRelayClient;
  cache: RelayListCache<GoogleAccountSummary>;
  accessTokens: GoogleAccessTokens;
};

/** Ohne `LOCAL_RUNTIME_GOOGLE_RELAY_URL` meldet jede Anfrage „nicht konfiguriert“, statt beim Start zu scheitern. */
export function googleAccountsModuleFromEnvironment(signedLicense: () => SignedRuntimeLicense | null): GoogleAccountsModule {
  const endpoint = process.env.LOCAL_RUNTIME_GOOGLE_RELAY_URL?.trim();
  const relay = endpoint ? new HttpRuntimeGoogleRelayClient(endpoint) : new UnavailableRuntimeGoogleRelayClient();
  return {relay, cache: new RelayListCache<GoogleAccountSummary>(), accessTokens: new RelayGoogleAccessTokens(relay, signedLicense)};
}
