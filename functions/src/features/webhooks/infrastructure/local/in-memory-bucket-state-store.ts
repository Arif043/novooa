import {type BucketState} from "../../../skills/domain/entities/token-bucket.js";
import {type BucketStateStore} from "../../../skills/domain/repositories/bucket-ports.js";

/**
 * Eimer im Arbeitsspeicher: Ein Prozess, also ist `transact` ohne Sperre atomar (kein `await` dazwischen).
 * Die Schlüssel sind durch die Anzahl der Auslöser begrenzt, abgelaufene Eimer räumt jeder Zugriff weg.
 */
export class InMemoryBucketStateStore implements BucketStateStore {
  private readonly states = new Map<string, BucketState>();

  async transact<Result>(
    key: string,
    mutate: (state: BucketState | undefined) => {next?: BucketState; result: Result},
  ): Promise<Result> {
    const now = Date.now();
    for (const [stored, state] of this.states) if (state.expiresAtMs <= now) this.states.delete(stored);
    const {next, result} = mutate(this.states.get(key));
    if (next !== undefined) this.states.set(key, next);
    return result;
  }
}
