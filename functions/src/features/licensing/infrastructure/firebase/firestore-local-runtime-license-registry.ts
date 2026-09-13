import {Timestamp} from "firebase-admin/firestore";
import {type LocalRuntimeLicense} from "../../domain/entities/local-runtime-license-lease.js";
import {type LocalRuntimeLicenseRegistry} from "../../domain/repositories/local-runtime-license-registry.js";
import {localRuntimeActivationTokenHash} from "../license-activation-token-hash.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";

export class LocalRuntimeLicenseError extends Error {}

export class FirestoreLocalRuntimeLicenseRegistry
implements LocalRuntimeLicenseRegistry {
  async licenseForActivationToken(
    token: string,
    now: Date,
  ): Promise<LocalRuntimeLicense> {
    const snapshot = await getDatabase()
      .collection("licenses")
      .doc(localRuntimeActivationTokenHash(token))
      .get();
    return licenseFromSnapshot(snapshot, now);
  }

  async licenseForId(licenseId: string, now: Date): Promise<LocalRuntimeLicense> {
    const snapshot = await getDatabase().collection("licenses")
      .where("licenseId", "==", licenseId).limit(2).get();
    if (snapshot.size !== 1) {
      throw new LocalRuntimeLicenseError("Die Lizenz ist ungültig.");
    }
    return licenseFromSnapshot(snapshot.docs[0], now);
  }
}

function licenseFromSnapshot(
  snapshot: FirebaseFirestore.DocumentSnapshot,
  now: Date,
): LocalRuntimeLicense {
  if (!snapshot.exists) throw new LocalRuntimeLicenseError("Der Lizenzschlüssel ist ungültig.");
  const data = snapshot.data();
  const expiresAt = expiresAtFrom(data?.expiresAt);
  if (data?.status !== "active" || (expiresAt && Date.parse(expiresAt) <= now.getTime())) {
    throw new LocalRuntimeLicenseError("Die Lizenz ist nicht aktiv.");
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
  throw new LocalRuntimeLicenseError("Die Lizenz ist ungültig.");
}

function requiredString(value: unknown): string {
  if (typeof value === "string" && value.trim().length > 0 && value.length <= 200) return value;
  throw new LocalRuntimeLicenseError("Die Lizenz ist ungültig.");
}
