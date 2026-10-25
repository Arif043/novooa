import {type GoogleAccount, type GoogleAccountStatus} from "../entities/google-account.js";
import {type GoogleAccountAuthorization} from "../entities/google-account-authorization.js";

export type GoogleAccountReference = {teamId: string; accountId: string};

export type GoogleAccountOwner = {teamId: string; runtimeLicenseId: string};

export interface GoogleAccountRepository {
  createAuthorization(authorization: GoogleAccountAuthorization): Promise<void>;

  /** Liefert die Anmeldung und löscht sie; abgelaufen oder unbekannt: `null`. */
  consumeAuthorization(id: string): Promise<GoogleAccountAuthorization | null>;

  findByGoogleUser(input: GoogleAccountOwner & {googleUserId: string}): Promise<GoogleAccount | null>;

  /** Speichert Konto und Refresh-Token zusammen und meldet der Runtime die geänderte Liste. */
  save(input: {account: GoogleAccount; refreshToken: string}): Promise<void>;

  listForLicense(owner: GoogleAccountOwner): Promise<GoogleAccount[]>;

  loadWithRefreshToken(reference: GoogleAccountReference): Promise<{account: GoogleAccount; refreshToken: string} | null>;

  updateStatus(input: GoogleAccountReference & {status: GoogleAccountStatus}): Promise<void>;
}
