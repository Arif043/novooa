import {randomUUID} from "node:crypto";
import {FieldValue, Timestamp, type DocumentData} from "firebase-admin/firestore";
import {
  type RuntimeMailRelayDeadLetter,
} from "../../domain/entities/runtime-mail-relay-event.js";
import {type RuntimeMailRelayEventStore} from
  "../../domain/repositories/runtime-mail-relay-event-store.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {
  deadLetterDocument,
  deadLetterFrom,
  deliveryFrom,
  eventDocument,
  pendingDocumentFromDeadLetter,
} from "./firestore-runtime-mail-relay-documents.js";

const maximumAttempts = 5;
const leaseDurationMs = 30_000;

export class FirestoreRuntimeMailRelayEventStore
implements RuntimeMailRelayEventStore {
  async enqueue(input: Parameters<RuntimeMailRelayEventStore["enqueue"]>[0]): Promise<void> {
    const reference = eventReference(input.event.eventId);
    await getDatabase().runTransaction(async (transaction) => {
      if ((await transaction.get(reference)).exists) return;
      transaction.create(reference, eventDocument(input));
      transaction.set(wakeupReference(input.licenseId), {
        licenseId: input.licenseId,
        communicationRevision: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    });
  }

  async lease(input: Parameters<RuntimeMailRelayEventStore["lease"]>[0]) {
    await this.recoverExpired(input.licenseId, input.now);
    const snapshots = await events()
      .where("licenseId", "==", input.licenseId)
      .where("status", "==", "pending")
      .where("nextAttemptAt", "<=", Timestamp.fromDate(input.now))
      .limit(input.limit).get();
    const deliveries = await Promise.all(snapshots.docs.map((document) =>
      this.claim(document.ref, input.now)));
    return deliveries.flatMap((delivery) => delivery ? [delivery] : []);
  }

  async acknowledge(input: Parameters<RuntimeMailRelayEventStore["acknowledge"]>[0]) {
    await getDatabase().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(eventReference(input.eventId));
      if (isMatchingLease(snapshot.data(), input)) transaction.delete(snapshot.ref);
    });
  }

  async reject(input: Parameters<RuntimeMailRelayEventStore["reject"]>[0]) {
    await getDatabase().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(eventReference(input.eventId));
      if (!isMatchingLease(snapshot.data(), input)) return;
      const active = snapshot.data() ?? {};
      if (attemptsFrom(active) >= maximumAttempts) {
        moveToDeadLetters(transaction, snapshot.ref, active, input.now, input.error);
        return;
      }
      transaction.update(snapshot.ref, retryUpdate(active, input.now, input.error));
    });
  }

  async listDeadLetters(licenseId: string): Promise<RuntimeMailRelayDeadLetter[]> {
    const snapshots = await deadLetters().where("licenseId", "==", licenseId).get();
    return snapshots.docs.flatMap((snapshot) => {
      const deadLetter = deadLetterFrom(snapshot.id, snapshot.data());
      return deadLetter ? [deadLetter] : [];
    });
  }

  async replay(input: Parameters<RuntimeMailRelayEventStore["replay"]>[0]) {
    await getDatabase().runTransaction(async (transaction) => {
      const deadLetter = deadLetterReference(input.eventId);
      const snapshot = await transaction.get(deadLetter);
      const data = snapshot.data();
      if (!data || data.licenseId !== input.licenseId || data.replayedAt !== null) {
        throw new Error("Das Dead-Letter-Ereignis kann nicht erneut zugestellt werden.");
      }
      transaction.set(eventReference(input.eventId), pendingDocumentFromDeadLetter(data, input.now));
      transaction.update(deadLetter, {replayedAt: Timestamp.fromDate(input.now)});
    });
  }

  private async claim(reference: FirebaseFirestore.DocumentReference, now: Date) {
    return getDatabase().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      const active = snapshot.data();
      if (!active || !isPending(active, now)) return null;
      if (attemptsFrom(active) >= maximumAttempts) {
        moveToDeadLetters(transaction, reference, active, now, "Maximale Zustellversuche erreicht.");
        return null;
      }
      const receipt = randomUUID();
      transaction.update(reference, leasedUpdate(active, now, receipt));
      const delivery = deliveryFrom(reference.id, active, receipt);
      return delivery ? {...delivery, attempt: attemptsFrom(active) + 1} : null;
    });
  }

  private async recoverExpired(licenseId: string, now: Date): Promise<void> {
    const snapshots = await events().where("licenseId", "==", licenseId)
      .where("status", "==", "leased")
      .where("leaseExpiresAt", "<=", Timestamp.fromDate(now)).limit(20).get();
    await Promise.all(snapshots.docs.map((snapshot) => getDatabase().runTransaction(async (transaction) => {
      const current = await transaction.get(snapshot.ref);
      const active = current.data();
      if (!active || !isExpiredLease(active, now)) return;
      if (attemptsFrom(active) >= maximumAttempts) {
        moveToDeadLetters(transaction, current.ref, active, now, "Die lokale Runtime hat die Zustellung nicht bestätigt.");
        return;
      }
      transaction.update(current.ref, retryUpdate(active, now, "Die Zustellfrist ist abgelaufen."));
    })));
  }
}

function events() {
  return getDatabase().collection("localRuntimeMailRelayEvents");
}

function deadLetters() {
  return getDatabase().collection("localRuntimeMailRelayDeadLetters");
}

function wakeupReference(licenseId: string) {
  return getDatabase().collection("localRuntimeWakeups").doc(licenseId);
}

function eventReference(eventId: string) {
  return events().doc(eventId);
}

function deadLetterReference(eventId: string) {
  return deadLetters().doc(eventId);
}

function isMatchingLease(data: DocumentData | undefined, input: {licenseId: string; receipt: string}) {
  return data?.licenseId === input.licenseId && data.status === "leased" && data.receipt === input.receipt;
}

function isPending(data: DocumentData, now: Date): boolean {
  return data.status === "pending" && data.nextAttemptAt instanceof Timestamp &&
    data.nextAttemptAt.toDate() <= now;
}

function isExpiredLease(data: DocumentData, now: Date): boolean {
  return data.status === "leased" && data.leaseExpiresAt instanceof Timestamp &&
    data.leaseExpiresAt.toDate() <= now;
}

function attemptsFrom(data: DocumentData): number {
  return typeof data.attempts === "number" ? data.attempts : 0;
}

function leasedUpdate(data: DocumentData, now: Date, receipt: string) {
  return {status: "leased", attempts: attemptsFrom(data) + 1, receipt,
    leaseExpiresAt: Timestamp.fromMillis(now.getTime() + leaseDurationMs)};
}

function retryUpdate(data: DocumentData, now: Date, error: string) {
  return {status: "pending", receipt: null, leaseExpiresAt: null, lastError: error,
    nextAttemptAt: Timestamp.fromMillis(now.getTime() + retryDelayMs(attemptsFrom(data)))};
}

function retryDelayMs(attempts: number): number {
  return Math.min(300_000, 30_000 * 2 ** Math.max(0, attempts - 1));
}

function moveToDeadLetters(
  transaction: FirebaseFirestore.Transaction,
  activeReference: FirebaseFirestore.DocumentReference,
  active: DocumentData,
  now: Date,
  error: string,
): void {
  transaction.set(deadLetterReference(activeReference.id), deadLetterDocument(active, now, error));
  transaction.delete(activeReference);
}
