import {type RateLimitDecision, type RateLimiter} from "../rate_limiting/domain/repositories/rate-limiter.js";
import {TokenBucketRateLimiter} from "../rate_limiting/domain/usecases/token-bucket-rate-limiter.js";
import {InMemoryBucketStateStore} from "../rate_limiting/infrastructure/local/in-memory-bucket-state-store.js";

/** Entscheidet vor der teuren Passwortprüfung, ob ein Anmeldeversuch angenommen wird. */
export interface LoginAttemptLimiter {
  take(clientKey: string): Promise<RateLimitDecision>;
}

const globalKey = "login";
const maxTrackedClients = 10_000;

/**
 * Zwei Stufen: Je Client bremst sie Passwort-Raten, global deckelt sie die
 * Zahl der scrypt-Hashes — auch wenn ein Angreifer viele Adressen nutzt. Die
 * Client-Stufe zuerst, damit ein einzelner lauter Client das globale Kontingent
 * nicht für alle aufbraucht.
 */
export class TwoStageLoginLimiter implements LoginAttemptLimiter {
  constructor(
    private readonly perClient: RateLimiter,
    private readonly global: RateLimiter,
  ) {}

  async take(clientKey: string): Promise<RateLimitDecision> {
    const client = await this.perClient.take(clientKey);
    if (!client.allowed) return client;
    return this.global.take(globalKey);
  }
}

/** Je Client 5 Versuche, dann 1 pro Minute; global 10, dann 1 alle 5 Sekunden (≤ 12 Hashes/Minute). */
export function createLoginAttemptLimiter(): LoginAttemptLimiter {
  return new TwoStageLoginLimiter(
    new TokenBucketRateLimiter(new InMemoryBucketStateStore(maxTrackedClients),
      {current: async () => ({capacity: 5, refillPerSecond: 1 / 60})}),
    new TokenBucketRateLimiter(new InMemoryBucketStateStore(),
      {current: async () => ({capacity: 10, refillPerSecond: 1 / 5})}),
  );
}
