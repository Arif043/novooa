import {onRequest} from "firebase-functions/v2/https";
import {type RuntimeLicense, type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {FirebaseRuntimeRelayLicenseVerifier} from
  "../../../licensing/infrastructure/firebase/firebase-runtime-relay-license-verifier.js";
import {localRuntimeLicenseSigningKey} from "../../../licensing/infrastructure/firebase/local-runtime-license-signing-key.js";
import {signedRuntimeLicenseFrom} from "../../../licensing/infrastructure/firebase/signed-runtime-license-input.js";
import {googleAccountSummaryFrom} from "../../domain/entities/google-account.js";
import {GoogleAuthorizationRevokedError} from "../../domain/repositories/google-oauth-provider.js";
import {beginGoogleAccountAuthorization} from "../../domain/usecases/begin-google-account-authorization.js";
import {IssueGoogleAccessToken} from "../../domain/usecases/issue-google-access-token.js";
import {logException} from "../../../../shared/logging/logger.js";
import {authorizationCodeVerifier, authorizationId, codeChallenge} from "../../../../shared/security/oauth-pkce.js";
import {
  googleAccountCipher,
  googleAccountEncryptionKey,
  googleAuthorizationProvider,
  googleOAuthClientSecret,
  googleOAuthProvider,
} from "../google/google-account-config.js";
import {FirestoreGoogleAccountRepository} from "./firestore-google-account-repository.js";

const verifier = new FirebaseRuntimeRelayLicenseVerifier();

type RelayCommand =
  | {type: "beginAuthorization"; license: SignedRuntimeLicense; loginHint?: string}
  | {type: "listAccounts"; license: SignedRuntimeLicense}
  | {type: "accessToken"; license: SignedRuntimeLicense; accountId: string};

/** Google-Relay der Runtime: Anmeldung beginnen, Konten auflisten, kurzlebige Zugriffstokens ausgeben. */
export const localRuntimeGoogleRelay = onRequest(
  {cors: false, invoker: "public", secrets: [localRuntimeLicenseSigningKey, googleOAuthClientSecret, googleAccountEncryptionKey]},
  async (request, response) => {
    if (request.method !== "POST") return void response.status(405).json({error: "Methode nicht erlaubt."});
    try {
      response.status(200).json(await execute(commandFrom(request.body)));
    } catch (error) {
      if (error instanceof GoogleAuthorizationRevokedError) {
        return void response.status(409).json({error: "reauthorization_required", message: error.message});
      }
      logException("local_runtime_google_relay.failed", error);
      response.status(401).json({error: "Die Google-Relay-Anfrage wurde abgelehnt."});
    }
  },
);

async function execute(command: RelayCommand): Promise<object> {
  const license = await verifier.verify(command.license);
  const repository = new FirestoreGoogleAccountRepository(googleAccountCipher());
  switch (command.type) {
  case "beginAuthorization": return begin(license, repository, command.loginHint);
  case "listAccounts": return {items: (await repository.listForLicense(ownerOf(license))).map(googleAccountSummaryFrom)};
  case "accessToken": return tokenFor(license, repository, command.accountId);
  }
}

function begin(license: RuntimeLicense, repository: FirestoreGoogleAccountRepository, loginHint?: string) {
  const codeVerifier = authorizationCodeVerifier();
  return beginGoogleAccountAuthorization({
    authorization: {
      id: authorizationId(), ...ownerOf(license), codeVerifier, expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    },
    codeChallenge: codeChallenge(codeVerifier), loginHint, repository, provider: googleAuthorizationProvider(),
  });
}

async function tokenFor(license: RuntimeLicense, repository: FirestoreGoogleAccountRepository, accountId: string) {
  const token = await new IssueGoogleAccessToken(repository, googleOAuthProvider()).execute({...ownerOf(license), accountId});
  return {accessToken: token.accessToken, expiresAt: token.expiresAt.toISOString()};
}

function ownerOf(license: RuntimeLicense) {
  return {teamId: license.workspaceId, runtimeLicenseId: license.licenseId};
}

function commandFrom(value: unknown): RelayCommand {
  const input = record(value);
  const license = signedRuntimeLicenseFrom(input.license);
  if (input.type === "listAccounts") return {type: "listAccounts", license};
  if (input.type === "accessToken") return {type: "accessToken", license, accountId: text(input.accountId, "accountId", 120)};
  if (input.type === "beginAuthorization") {
    const loginHint = input.loginHint === undefined ? undefined : text(input.loginHint, "loginHint", 320);
    return {type: "beginAuthorization", license, loginHint};
  }
  throw new Error("Unbekannte Google-Relay-Anfrage.");
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new Error("Ungültige Google-Relay-Anfrage.");
}

function text(value: unknown, name: string, max: number): string {
  if (typeof value !== "string" || value.trim().length === 0 || value.length > max) throw new Error(`${name} ist ungültig.`);
  return value.trim();
}
