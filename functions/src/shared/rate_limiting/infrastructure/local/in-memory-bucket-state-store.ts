import {type BucketState} from "../../domain/entities/token-bucket.js";
import {type BucketStateStore} from "../../domain/repositories/bucket-ports.js";

/**
 * Eimer im Arbeitsspeicher: Ein Prozess, also ist `transact` ohne Sperre atomar (kein `await` dazwischen).
 * Abgelaufene Eimer räumt jeder Zugriff weg. Sind die Schlüssel nicht von vornherein begrenzt (etwa
 * Client-Adressen), deckelt `maxKeys` den Speicher: Dann fällt der am längsten nicht genutzte Eimer weg.
 */
export class InMemoryBucketStateStore implements BucketStateStore {
  private readonly states = new Map<string, BucketState>();

  constructor(private readonly maxKeys = Number.POSITIVE_INFINITY) {}

  async transact<Result>(
    key: string,
    mutate: (state: BucketState | undefined) => {next?: BucketState; result: Result},
  ): Promise<Result> {
    const now = Date.now();
    for (const [stored, state] of this.states) if (state.expiresAtMs <= now) this.states.delete(stored);
    const {next, result} = mutate(this.states.get(key));
    if (next !== undefined) this.store(key, next);
    return result;
  }

  private store(key: string, state: BucketState): void {
    // Neu einfügen, damit die Map-Reihenfolge der letzten Nutzung entspricht.
    this.states.delete(key);
    this.states.set(key, state);
    while (this.states.size > this.maxKeys) {
      const oldest = this.states.keys().next().value as string;
      this.states.delete(oldest);
    }
  }
}
