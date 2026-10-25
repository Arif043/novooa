import {type GoogleAccount, type GoogleAccountStatus} from "../entities/google-account.js";
import {type GoogleAccountAuthorization} from "../entities/google-account-authorization.js";
import {type GoogleAccountRepository} from "../repositories/google-account-repository.js";
import {
  type GoogleAccessToken,
  type GoogleOAuthProvider,
  type GoogleTokenGrant,
} from "../repositories/google-oauth-provider.js";

export function storedAccount(overrides: Partial<GoogleAccount> = {}): GoogleAccount {
  return {
    id: "konto-1", teamId: "team-1", runtimeLicenseId: "lizenz-1", googleUserId: "sub-1",
    email: "alt@example.com", status: "active",
    sharedItems: [{id: "ordner-1", name: "Rechnungen", mimeType: "application/vnd.google-apps.folder"}],
    createdAt: new Date("2026-01-01T00:00:00Z"), updatedAt: new Date("2026-01-01T00:00:00Z"),
    ...overrides,
  };
}

export class MemoryGoogleAccountRepository implements GoogleAccountRepository {
  authorization: GoogleAccountAuthorization | null = {
    id: "anmeldung-1", teamId: "team-1", runtimeLicenseId: "lizenz-1",
    codeVerifier: "verifier", expiresAt: new Date(Date.now() + 60_000),
  };
  saved: Array<{account: GoogleAccount; refreshToken: string}> = [];
  statuses: GoogleAccountStatus[] = [];

  constructor(private readonly account: GoogleAccount | null = null) {}

  async createAuthorization(authorization: GoogleAccountAuthorization) { this.authorization = authorization; }
  async consumeAuthorization() {
    const authorization = this.authorization;
    this.authorization = null;
    return authorization;
  }
  async findByGoogleUser() { return this.account; }
  async save(input: {account: GoogleAccount; refreshToken: string}) { this.saved.push(input); }
  async listForLicense() { return this.account ? [this.account] : []; }
  async loadWithRefreshToken() { return this.account ? {account: this.account, refreshToken: "refresh-alt"} : null; }
  async updateStatus(input: {status: GoogleAccountStatus}) { this.statuses.push(input.status); }
}

export class FakeGoogleOAuthProvider implements GoogleOAuthProvider {
  grant: GoogleTokenGrant = {accessToken: "access-neu", refreshToken: "refresh-neu", expiresInSeconds: 3600};
  refresh: () => Promise<GoogleAccessToken> = async () => ({accessToken: "access-frisch", expiresInSeconds: 3599});
  describedIds: string[] = [];

  authorizationUrl(input: {state: string}) { return `https://google.test/auth?state=${input.state}`; }
  async exchangeCode() { return this.grant; }
  async refreshAccessToken() { return this.refresh(); }
  async loadIdentity() { return {googleUserId: "sub-1", email: "neu@example.com"}; }
  async describeItems(input: {ids: string[]}) {
    this.describedIds = input.ids;
    return input.ids.map((id) => ({id, name: `Name ${id}`, mimeType: "application/pdf"}));
  }
}
