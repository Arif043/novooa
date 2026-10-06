export type BucketConfig = {
  /** Größe des Eimers = größter Stoß aufeinanderfolgender Anfragen. */
  capacity: number;
  /** Token, die pro Sekunde nachgefüllt werden = Dauerrate. */
  refillPerSecond: number;
};

export type BucketState = {
  tokens: number;
  updatedAtMs: number;
  /** Danach darf der Zustand gelöscht werden: ein Eimer, der sich bis dahin gefüllt hat, ist von einem neuen nicht zu unterscheiden. */
  expiresAtMs: number;
};

export type BucketTake = {
  allowed: boolean;
  state: BucketState;
  /** Wartezeit bis zum nächsten verfügbaren Token (0, wenn erlaubt). */
  retryAfterSeconds: number;
};

export const defaultBucketConfig: BucketConfig = {capacity: 20, refillPerSecond: 0.5};

const maximumCapacity = 10_000;
const maximumRefillPerSecond = 1_000;
const minimumLifetimeMs = 24 * 60 * 60 * 1000;

/** Ungültige oder fehlende Werte (Remote Config liefert bei Fehlern `0`) fallen auf die Standardwerte zurück. */
export function normalizedBucketConfig(raw: Partial<BucketConfig>): BucketConfig {
  const capacity = Math.floor(raw.capacity ?? Number.NaN);
  const refill = raw.refillPerSecond ?? Number.NaN;
  return {
    capacity: Number.isFinite(capacity) && capacity >= 1 ? Math.min(capacity, maximumCapacity) : defaultBucketConfig.capacity,
    refillPerSecond: Number.isFinite(refill) && refill > 0 ? Math.min(refill, maximumRefillPerSecond) : defaultBucketConfig.refillPerSecond,
  };
}

/**
 * Entnimmt einem Token Bucket ein Token. Ein neuer Eimer ist voll; zwischen zwei Aufrufen füllt er sich mit
 * `refillPerSecond` bis `capacity` nach (aus der verstrichenen Zeit berechnet, kein Timer nötig). Eine abgelehnte
 * Anfrage verbraucht nichts.
 */
export function takeToken(previous: BucketState | undefined, config: BucketConfig, nowMs: number): BucketTake {
  const elapsedSeconds = previous === undefined ? 0 : Math.max(0, nowMs - previous.updatedAtMs) / 1000;
  const refilled = previous === undefined
    ? config.capacity
    : Math.min(config.capacity, previous.tokens + elapsedSeconds * config.refillPerSecond);
  const allowed = refilled >= 1;
  const tokens = allowed ? refilled - 1 : refilled;
  return {
    allowed,
    retryAfterSeconds: allowed ? 0 : Math.max(1, Math.ceil((1 - refilled) / config.refillPerSecond)),
    state: {tokens, updatedAtMs: nowMs, expiresAtMs: nowMs + Math.max(minimumLifetimeMs, (config.capacity / config.refillPerSecond) * 1000)},
  };
}
