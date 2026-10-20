import {randomBytes, randomUUID} from "node:crypto";
import {Timestamp} from "firebase-admin/firestore";
import {type RuntimeLicense, type SignedRuntimeLicense, maxUsersFrom} from "../../domain/entities/runtime-license-lease.js";
import {type RuntimeLicenseActivationGrant, type RuntimeLicenseRegistry} from "../../domain/repositories/runtime-license-registry.js";
import {localRuntimeActivationTokenHash, runtimeActivationSecretHash} from "../license-activation-token-hash.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";

export class RuntimeLicenseError extends Error {}
export class FirestoreRuntimeLicenseRegistry implements RuntimeLicenseRegistry {
  async activate(token: string, now: Date): Promise<RuntimeLicenseActivationGrant> {
    const reference = getDatabase().collection("licenses").doc(localRuntimeActivationTokenHash(token));
    const activationId = randomUUID();
    const activationSecret = randomBytes(32).toString("base64url");
    return getDatabase().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      const license = activeLicenseFromSnapshot(snapshot, now, false);
      if (snapshot.data()?.inUse === true) throw new RuntimeLicenseError("Die Lizenz wird bereits verwendet.");
      transaction.update(reference, {
        inUse: true, activationId, activationSecretHash: runtimeActivationSecretHash(activationSecret),
        activatedAt: Timestamp.fromDate(now), updatedAt: Timestamp.fromDate(now),
      });
      return {license: {...license, activationId}, activationSecret};
    });
  }

  async release(license: RuntimeLicense, activationSecret: string, now: Date): Promise<void> {
    const snapshot = await this.snapshotForId(license.licenseId);
    await getDatabase().runTransaction(async (transaction) => {
      const current = await transaction.get(snapshot.ref);
      const data = current.data();
      if (!current.exists || data?.inUse !== true || data.activationId !== license.activationId ||
        data.activationSecretHash !== runtimeActivationSecretHash(activationSecret)) {
        throw new RuntimeLicenseError("Die Lizenzfreigabe wurde abgelehnt.");
      }
      transaction.update(snapshot.ref, {
        inUse: false, activationId: null, activationSecretHash: null,
        releasedAt: Timestamp.fromDate(now), updatedAt: Timestamp.fromDate(now),
      });
    });
  }

  async licenseForId(licenseId: string, now: Date): Promise<RuntimeLicense> {
    const snapshot = await this.snapshotForId(licenseId);
    return activeLicenseFromSnapshot(snapshot, now, true);
  }

  async verifyActiveActivation(
    license: SignedRuntimeLicense,
    activationSecret: string,
    now: Date,
  ): Promise<RuntimeLicense> {
    const snapshot = await this.snapshotForId(license.payload.licenseId);
    const active = activeLicenseFromSnapshot(snapshot, now, true);
    const data = snapshot.data();
    if (active.activationId !== license.payload.activationId ||
      data.activationSecretHash !== runtimeActivationSecretHash(activationSecret)) {
      throw new RuntimeLicenseError("Die Runtime-Aktivierung ist ungültig.");
    }
    return active;
  }

  private async snapshotForId(licenseId: string): Promise<FirebaseFirestore.QueryDocumentSnapshot> {
    const snapshots = await getDatabase().collection("licenses").where("licenseId", "==", licenseId).limit(2).get();
    if (snapshots.size !== 1) throw new RuntimeLicenseError("Die Lizenz ist ungültig.");
    return snapshots.docs[0];
  }
}

function activeLicenseFromSnapshot(
  snapshot: FirebaseFirestore.DocumentSnapshot,
  now: Date,
  requireInUse: boolean,
): RuntimeLicense {
  if (!snapshot.exists) throw new RuntimeLicenseError("Der Lizenzschlüssel ist ungültig.");
  const data = snapshot.data();
  const expiresAt = expiresAtFrom(data?.expiresAt);
  const usageIsValid = requireInUse ? data?.inUse === true : data?.inUse === false;
  const hasExpired = Date.parse(expiresAt) <= now.getTime();
  if (!usageIsValid || hasExpired) {
    throw new RuntimeLicenseError("Die Lizenz ist nicht aktiv.");
  }
  const activationId = requireInUse ? requiredString(data?.activationId) : "pending";
  return {
    licenseId: requiredString(data?.licenseId), licenseName: requiredString(data?.name), activationId,
    workspaceId: requiredString(data?.workspaceId), issuedAt: now.toISOString(), expiresAt,
    maxUsers: maxUsersFrom(data?.maxUsers),
  };
}

function expiresAtFrom(value: unknown): string {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  throw new RuntimeLicenseError("Die Lizenz ist ungültig.");
}
function requiredString(value: unknown): string {
  if (typeof value === "string" && value.trim().length > 0 && value.length <= 200) return value;
  throw new RuntimeLicenseError("Die Lizenz ist ungültig.");
}
