import {type GoogleAccountOwner, type GoogleAccountRepository} from "../repositories/google-account-repository.js";
import {
  GoogleAuthorizationRevokedError,
  type GoogleOAuthProvider,
} from "../repositories/google-oauth-provider.js";

export type IssuedGoogleAccessToken = {
  accessToken: string;
  expiresAt: Date;
};

/**
 * Gibt der Runtime ein kurzlebiges Zugriffstoken für ihr Konto. Das Refresh-Token und das Client-Secret
 * verlassen Firebase nie; die Runtime ruft Google mit dem Zugriffstoken selbst auf.
 */
export class IssueGoogleAccessToken {
  constructor(
    private readonly repository: GoogleAccountRepository,
    private readonly provider: GoogleOAuthProvider,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async execute(input: GoogleAccountOwner & {accountId: string}): Promise<IssuedGoogleAccessToken> {
    const stored = await this.repository.loadWithRefreshToken({teamId: input.teamId, accountId: input.accountId});
    if (stored === null || stored.account.runtimeLicenseId !== input.runtimeLicenseId) {
      throw new Error("Das Google-Konto gehört nicht zu dieser Runtime.");
    }
    if (stored.account.status !== "active") throw new GoogleAuthorizationRevokedError();
    try {
      const token = await this.provider.refreshAccessToken(stored.refreshToken);
      return {accessToken: token.accessToken, expiresAt: new Date(this.now().getTime() + token.expiresInSeconds * 1000)};
    } catch (error) {
      if (error instanceof GoogleAuthorizationRevokedError) {
        await this.repository.updateStatus({teamId: input.teamId, accountId: input.accountId, status: "reauthorizationRequired"});
      }
      throw error;
    }
  }
}
