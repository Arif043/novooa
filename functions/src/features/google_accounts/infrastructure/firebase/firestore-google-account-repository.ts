import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {type GoogleAccount, type GoogleAccountStatus} from "../../domain/entities/google-account.js";
import {type GoogleAccountAuthorization} from "../../domain/entities/google-account-authorization.js";
import {
  type GoogleAccountOwner,
  type GoogleAccountReference,
  type GoogleAccountRepository,
} from "../../domain/repositories/google-account-repository.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {type CredentialCipher} from "../../../../shared/security/credential-cipher.js";
import {
  accountDocument,
  accountFrom,
  authorizationDocument,
  authorizationFrom,
} from "./firestore-google-account-documents.js";

/**
 * Konten unter `teams/{team}/googleAccounts`, Refresh-Tokens verschlüsselt in `googleAccountCredentials`.
 * Begonnene Anmeldungen liegen oben unter ihrer ID: Der Callback kennt nur sie (`state`), nicht das Team.
 */
export class FirestoreGoogleAccountRepository implements GoogleAccountRepository {
  constructor(private readonly cipher: CredentialCipher, private readonly now: () => Date = () => new Date()) {}

  async createAuthorization(authorization: GoogleAccountAuthorization): Promise<void> {
    await authorizations().doc(authorization.id).set(authorizationDocument(authorization));
  }

  async consumeAuthorization(id: string): Promise<GoogleAccountAuthorization | null> {
    const reference = authorizations().doc(id);
    const data = await getDatabase().runTransaction(async (transaction) => {
      const current = await transaction.get(reference);
      if (!current.exists) return null;
      transaction.delete(reference);
      return current.data() ?? null;
    });
    return data === null ? null : authorizationFrom(data, this.now());
  }

  async findByGoogleUser(input: GoogleAccountOwner & {googleUserId: string}): Promise<GoogleAccount | null> {
    const snapshot = await accounts(input.teamId).where("runtimeLicenseId", "==", input.runtimeLicenseId)
      .where("googleUserId", "==", input.googleUserId).limit(1).get();
    return snapshot.empty ? null : accountFrom(snapshot.docs[0].data(), snapshot.docs[0].id);
  }

  async save(input: {account: GoogleAccount; refreshToken: string}): Promise<void> {
    const batch = getDatabase().batch();
    batch.set(accounts(input.account.teamId).doc(input.account.id), accountDocument(input.account));
    batch.set(credentials(input.account), {refreshToken: this.cipher.encrypt(input.refreshToken)});
    await batch.commit();
    await signalRuntimeGoogleAccountsChanged(input.account.runtimeLicenseId);
  }

  async listForLicense(owner: GoogleAccountOwner): Promise<GoogleAccount[]> {
    const snapshot = await accounts(owner.teamId).where("runtimeLicenseId", "==", owner.runtimeLicenseId).get();
    return snapshot.docs.map((document) => accountFrom(document.data(), document.id));
  }

  async loadWithRefreshToken(reference: GoogleAccountReference) {
    const snapshot = await accounts(reference.teamId).doc(reference.accountId).get();
    if (!snapshot.exists) return null;
    const account = accountFrom(snapshot.data() ?? {}, snapshot.id);
    const secret = await credentials(account).get();
    const encrypted = secret.get("refreshToken") as unknown;
    if (typeof encrypted !== "string") return null;
    return {account, refreshToken: this.cipher.decrypt(encrypted)};
  }

  async updateStatus(input: GoogleAccountReference & {status: GoogleAccountStatus}): Promise<void> {
    const reference = accounts(input.teamId).doc(input.accountId);
    await reference.update({status: input.status, updatedAt: Timestamp.fromDate(this.now())});
    const snapshot = await reference.get();
    const licenseId = snapshot.get("runtimeLicenseId") as unknown;
    if (typeof licenseId === "string") await signalRuntimeGoogleAccountsChanged(licenseId);
  }
}

/** Die Runtime hört auf ihr Wake-up-Dokument; die Revision sagt nur, dass sie die Kontenliste neu laden soll. */
async function signalRuntimeGoogleAccountsChanged(licenseId: string): Promise<void> {
  await getDatabase().collection("localRuntimeWakeups").doc(licenseId).set({
    licenseId, googleAccountsRevision: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}

function authorizations() {
  return getDatabase().collection("googleAccountAuthorizations");
}

function team(teamId: string) {
  return getDatabase().collection("teams").doc(teamId);
}

function accounts(teamId: string) {
  return team(teamId).collection("googleAccounts");
}

function credentials(account: Pick<GoogleAccount, "teamId" | "id">) {
  return team(account.teamId).collection("googleAccountCredentials").doc(account.id);
}
