export type RateLimitDecision = {
  allowed: boolean;
  /** Wartezeit in Sekunden, wenn nicht erlaubt. */
  retryAfterSeconds: number;
};

/** Begrenzt Anfragen je Schlüssel (etwa je Lizenz, je Auslöser oder je Client-Adresse). */
export interface RateLimiter {
  take(key: string): Promise<RateLimitDecision>;
}
