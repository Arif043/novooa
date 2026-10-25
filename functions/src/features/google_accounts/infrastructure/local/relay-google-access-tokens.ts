import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type GoogleAccessTokens} from "../../domain/repositories/google-access-tokens.js";
import {type RuntimeGoogleRelayClient} from "./runtime-google-relay-client.js";

const safetyMarginMilliseconds = 60_000;

/**
 * Holt Zugriffstokens über das Relay und hält sie bis kurz vor Ablauf im Speicher. Gleichzeitige Bausteine
 * teilen sich eine Anfrage, damit ein Lauf mit vielen Drive-Schritten das Relay nicht vielfach aufruft.
 */
export class RelayGoogleAccessTokens implements GoogleAccessTokens {
  private readonly cache = new Map<string, {token: string; expiresAtMs: number}>();
  private readonly pending = new Map<string, Promise<string>>();

  constructor(
    private readonly relay: Pick<RuntimeGoogleRelayClient, "accessToken">,
    private readonly signedLicense: () => SignedRuntimeLicense | null,
    private readonly now: () => number = Date.now,
  ) {}

  async token(accountId: string): Promise<string> {
    const cached = this.cache.get(accountId);
    if (cached !== undefined && cached.expiresAtMs - safetyMarginMilliseconds > this.now()) return cached.token;
    const running = this.pending.get(accountId);
    if (running !== undefined) return running;
    const fetched = this.fetch(accountId).finally(() => this.pending.delete(accountId));
    this.pending.set(accountId, fetched);
    return fetched;
  }

  invalidate(accountId: string): void {
    this.cache.delete(accountId);
  }

  private async fetch(accountId: string): Promise<string> {
    const license = this.signedLicense();
    if (license === null) throw new Error("Die lokale Runtime hat keine aktive Lizenz.");
    const issued = await this.relay.accessToken(license, accountId);
    this.cache.set(accountId, {token: issued.accessToken, expiresAtMs: issued.expiresAt.getTime()});
    return issued.accessToken;
  }
}
