import {Timestamp} from "firebase-admin/firestore";
import {type RuntimeLicense} from "../../domain/entities/runtime-license-lease.js";
import {type RuntimeLicenseRegistry} from "../../domain/repositories/runtime-license-registry.js";
import {localRuntimeActivationTokenHash} from "../license-activation-token-hash.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";

export class RuntimeLicenseError extends Error {}

export class FirestoreRuntimeLicenseRegistry
implements RuntimeLicenseRegistry {
  async licenseForActivationToken(
    token: string,
    now: Date,
  ): Promise<RuntimeLicense> {
    const snapshot = await getDatabase()
      .collection("licenses")
      .doc(localRuntimeActivationTokenHash(token))
      .get();
    return licenseFromSnapshot(snapshot, now);
  }

  async licenseForId(licenseId: string, now: Date): Promise<RuntimeLicense> {
    const snapshot = await getDatabase().collection("licenses")
      .where("licenseId", "==", licenseId).limit(2).get();
    if (snapshot.size !== 1) {
      throw new RuntimeLicenseError("Die Lizenz ist ungültig.");
    }
    return licenseFromSnapshot(snapshot.docs[0], now);
  }
}

function licenseFromSnapshot(
  snapshot: FirebaseFirestore.DocumentSnapshot,
  now: Date,
): RuntimeLicense {
  if (!snapshot.exists) throw new RuntimeLicenseError("Der Lizenzschlüssel ist ungültig.");
  const data = snapshot.data();
  const expiresAt = expiresAtFrom(data?.expiresAt);
  if (data?.status !== "active" || (expiresAt && Date.parse(expiresAt) <= now.getTime())) {
    throw new RuntimeLicenseError("Die Lizenz ist nicht aktiv.");
  }
  return {
    licenseId: requiredString(data?.licenseId),
    workspaceId: requiredString(data?.workspaceId),
    issuedAt: now.toISOString(),
    expiresAt,
  };
}

function expiresAtFrom(value: unknown): string | undefined {
  if (value === undefined || value === null) return undefined;
  if (value instanceof Timestamp) return value.toDate().toISOString();
  throw new RuntimeLicenseError("Die Lizenz ist ungültig.");
}

function requiredString(value: unknown): string {
  if (typeof value === "string" && value.trim().length > 0 && value.length <= 200) return value;
  throw new RuntimeLicenseError("Die Lizenz ist ungültig.");
}
