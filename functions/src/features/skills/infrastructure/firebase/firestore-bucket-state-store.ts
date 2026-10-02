import {createHash} from "node:crypto";
import {Timestamp} from "firebase-admin/firestore";
import {type BucketState} from "../../domain/entities/token-bucket.js";
import {type BucketStateStore} from "../../domain/repositories/bucket-ports.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";

export const rateLimitCollection = "skillsRelayRateLimits";

/**
 * Ein Dokument je Schlüssel, in einer Transaktion gelesen und geschrieben. Das Dokument heißt wie der SHA-256 des
 * Schlüssels (keine Sonderzeichen); `expiresAt` steuert die TTL-Richtlinie, die alte Eimer entfernt. Nur Server
 * greifen darauf zu (keine Client-Regeln).
 */
export class FirestoreBucketStateStore implements BucketStateStore {
  transact<Result>(
    key: string,
    mutate: (state: BucketState | undefined) => {next?: BucketState; result: Result},
  ): Promise<Result> {
    const reference = getDatabase().collection(rateLimitCollection).doc(createHash("sha256").update(key).digest("hex"));
    return getDatabase().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      const {next, result} = mutate(snapshot.exists ? stateFrom(snapshot.data()) : undefined);
      if (next) {
        transaction.set(reference, {tokens: next.tokens, updatedAtMs: next.updatedAtMs, expiresAt: Timestamp.fromMillis(next.expiresAtMs)});
      }
      return result;
    });
  }
}

function stateFrom(data: FirebaseFirestore.DocumentData | undefined): BucketState | undefined {
  if (typeof data?.tokens !== "number" || typeof data.updatedAtMs !== "number" || !(data.expiresAt instanceof Timestamp)) return undefined;
  return {tokens: data.tokens, updatedAtMs: data.updatedAtMs, expiresAtMs: data.expiresAt.toMillis()};
}
