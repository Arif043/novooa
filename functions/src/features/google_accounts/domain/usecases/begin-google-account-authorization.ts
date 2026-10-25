import {type GoogleAccountAuthorization} from "../entities/google-account-authorization.js";
import {type GoogleAccountRepository} from "../repositories/google-account-repository.js";
import {type GoogleOAuthProvider} from "../repositories/google-oauth-provider.js";

/** Merkt sich die Anmeldung und liefert die Google-Adresse mit Login und Picker. */
export async function beginGoogleAccountAuthorization(input: {
  authorization: GoogleAccountAuthorization;
  codeChallenge: string;
  loginHint?: string;
  repository: GoogleAccountRepository;
  provider: GoogleOAuthProvider;
}): Promise<{authorizationUrl: string}> {
  await input.repository.createAuthorization(input.authorization);
  const authorizationUrl = input.provider.authorizationUrl({
    state: input.authorization.id,
    codeChallenge: input.codeChallenge,
    loginHint: input.loginHint,
  });
  return {authorizationUrl};
}
