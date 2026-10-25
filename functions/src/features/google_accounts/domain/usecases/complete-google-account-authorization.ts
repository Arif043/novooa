import {
  mergedSharedItems,
  type GoogleAccount,
  type GoogleDriveItem,
} from "../entities/google-account.js";
import {type GoogleAccountAuthorization} from "../entities/google-account-authorization.js";
import {type GoogleAccountRepository} from "../repositories/google-account-repository.js";
import {
  type GoogleIdentity,
  type GoogleOAuthProvider,
  type GoogleTokenGrant,
} from "../repositories/google-oauth-provider.js";

export type CompleteGoogleAccountAuthorizationInput = {
  authorizationId: string;
  authorizationCode: string;
  pickedItemIds: string[];
  /** ID für ein neu verbundenes Konto; ein bekanntes behält seine. */
  newAccountId: string;
  repository: GoogleAccountRepository;
  provider: GoogleOAuthProvider;
  now: Date;
};

/**
 * Schließt die Anmeldung ab. Verbindet jemand dasselbe Google-Konto erneut (etwa um weitere Dateien
 * freizugeben), bleiben ID und bisherige Freigaben erhalten: Bausteine, die darauf zeigen, bleiben gültig.
 */
export async function completeGoogleAccountAuthorization(
  input: CompleteGoogleAccountAuthorizationInput,
): Promise<GoogleAccount> {
  const authorization = await input.repository.consumeAuthorization(input.authorizationId);
  if (authorization === null) throw new Error("Die Google-Anmeldung ist ungültig oder abgelaufen.");
  const grant = await input.provider.exchangeCode({code: input.authorizationCode, codeVerifier: authorization.codeVerifier});
  const identity = await input.provider.loadIdentity(grant.accessToken);
  const picked = await input.provider.describeItems({accessToken: grant.accessToken, ids: input.pickedItemIds});
  const existing = await input.repository.findByGoogleUser({...ownerOf(authorization), googleUserId: identity.googleUserId});
  const account = accountFrom(input, authorization, identity, picked, existing);
  await input.repository.save({account, refreshToken: refreshTokenFrom(grant)});
  return account;
}

function ownerOf(authorization: GoogleAccountAuthorization) {
  return {teamId: authorization.teamId, runtimeLicenseId: authorization.runtimeLicenseId};
}

function accountFrom(
  input: CompleteGoogleAccountAuthorizationInput,
  authorization: GoogleAccountAuthorization,
  identity: GoogleIdentity,
  picked: GoogleDriveItem[],
  existing: GoogleAccount | null,
): GoogleAccount {
  return {
    id: existing?.id ?? input.newAccountId,
    ...ownerOf(authorization),
    googleUserId: identity.googleUserId,
    email: identity.email,
    status: "active",
    sharedItems: mergedSharedItems(existing?.sharedItems ?? [], picked),
    createdAt: existing?.createdAt ?? input.now,
    updatedAt: input.now,
  };
}

function refreshTokenFrom(grant: GoogleTokenGrant): string {
  // Ohne Refresh-Token könnte die Runtime nach einer Stunde nicht mehr zugreifen; die Anmeldung erzwingt
  // die Einwilligung, also fehlt es nur bei einem Fehler auf Googles Seite.
  if (!grant.refreshToken) throw new Error("Google hat kein Refresh-Token geliefert.");
  return grant.refreshToken;
}
