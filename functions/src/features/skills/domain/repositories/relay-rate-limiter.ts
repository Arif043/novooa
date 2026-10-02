export type RateLimitDecision = {
  allowed: boolean;
  /** Wartezeit in Sekunden, wenn nicht erlaubt. */
  retryAfterSeconds: number;
};

/** Begrenzt Anfragen je Schlüssel (hier: je Lizenz). */
export interface RelayRateLimiter {
  take(key: string): Promise<RateLimitDecision>;
}
