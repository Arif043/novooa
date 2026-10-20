import {type RateLimitDecision, type RateLimiter} from "../rate_limiting/domain/repositories/rate-limiter.js";
import {TokenBucketRateLimiter} from "../rate_limiting/domain/usecases/token-bucket-rate-limiter.js";
import {InMemoryBucketStateStore} from "../rate_limiting/infrastructure/local/in-memory-bucket-state-store.js";

/** Ein Anmeldeversuch: von welcher Adresse, und – wenn bekannt – für welchen Anmeldenamen. */
export type LoginAttempt = {client: string; account?: string};

/** Entscheidet vor der teuren Passwortprüfung, ob ein Anmeldeversuch angenommen wird. */
export interface LoginAttemptLimiter {
  take(attempt: LoginAttempt): Promise<RateLimitDecision>;
}

const globalKey = "login";
const maxTrackedKeys = 10_000;

/**
 * Drei Stufen: Je Client bremst sie Passwort-Raten von einer Adresse, je Anmeldename das Raten gegen ein Konto
 * von vielen Adressen (und hinter einem Reverse Proxy, wo alle Clients eine Adresse teilen), global deckelt sie
 * die Zahl der scrypt-Hashes. Die engeren Stufen zuerst, damit ein einzelner lauter Client das globale
 * Kontingent nicht für alle aufbraucht.
 */
export class StagedLoginLimiter implements LoginAttemptLimiter {
  constructor(
    private readonly perClient: RateLimiter,
    private readonly perAccount: RateLimiter,
    private readonly global: RateLimiter,
  ) {}

  async take({client, account}: LoginAttempt): Promise<RateLimitDecision> {
    const byClient = await this.perClient.take(client);
    if (!byClient.allowed) return byClient;
    if (account !== undefined && account.length > 0) {
      const byAccount = await this.perAccount.take(account);
      if (!byAccount.allowed) return byAccount;
    }
    return this.global.take(globalKey);
  }
}

/** Je Client und je Anmeldename 5 Versuche, dann 1 pro Minute; global 10, dann 1 alle 5 Sekunden (≤ 12 Hashes/Minute). */
export function createLoginAttemptLimiter(): LoginAttemptLimiter {
  const fivePerMinute = {current: async () => ({capacity: 5, refillPerSecond: 1 / 60})};
  return new StagedLoginLimiter(
    new TokenBucketRateLimiter(new InMemoryBucketStateStore(maxTrackedKeys), fivePerMinute),
    new TokenBucketRateLimiter(new InMemoryBucketStateStore(maxTrackedKeys), fivePerMinute),
    new TokenBucketRateLimiter(new InMemoryBucketStateStore(),
      {current: async () => ({capacity: 10, refillPerSecond: 1 / 5})}),
  );
}
