import {takeToken} from "../entities/token-bucket.js";
import {type BucketSettings, type BucketStateStore} from "../repositories/bucket-ports.js";
import {type RateLimitDecision, type RelayRateLimiter} from "../repositories/relay-rate-limiter.js";

/** Token-Bucket-Begrenzung je Schlüssel. Kapazität und Rate kommen bei jedem Aufruf aus den [BucketSettings]. */
export class TokenBucketRateLimiter implements RelayRateLimiter {
  constructor(
    private readonly store: BucketStateStore,
    private readonly settings: BucketSettings,
    private readonly now: () => number = Date.now,
  ) {}

  async take(key: string): Promise<RateLimitDecision> {
    const config = await this.settings.current();
    return this.store.transact(key, (state) => {
      const taken = takeToken(state, config, this.now());
      return {
        // Eine abgelehnte Anfrage ändert nichts: Der nächste Aufruf rechnet vom selben Stand aus weiter.
        ...(taken.allowed ? {next: taken.state} : {}),
        result: {allowed: taken.allowed, retryAfterSeconds: taken.retryAfterSeconds},
      };
    });
  }
}
