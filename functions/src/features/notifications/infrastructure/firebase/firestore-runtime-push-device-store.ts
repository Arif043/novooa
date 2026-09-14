import {createHash} from "node:crypto";
import {FieldValue, type QueryDocumentSnapshot} from "firebase-admin/firestore";
import {type RuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimePushDevice} from "../../domain/entities/runtime-push.js";
import {type RuntimePushDeviceStore} from
  "../../domain/repositories/runtime-push-device-store.js";
import {
  type FcmTokenDocument,
  type FcmTokenStore,
} from "./firebase-push-notification-sender.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";

const collectionName = "localRuntimePushDevices";

export class FirestoreRuntimePushDeviceStore
implements RuntimePushDeviceStore {
  async save(
    license: RuntimeLicense,
    device: RuntimePushDevice,
  ): Promise<void> {
    const reference = deviceReference(device.token);
    await reference.set({
      licenseId: license.licenseId,
      workspaceId: license.workspaceId,
      token: device.token,
      platform: device.platform,
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }

  async remove(licenseId: string, token: string): Promise<void> {
    const reference = deviceReference(token);
    const snapshot = await reference.get();
    if (snapshot.data()?.licenseId === licenseId) await reference.delete();
  }
}

export class FirestoreLocalRuntimeFcmTokenStore implements FcmTokenStore {
  async tokensForRecipient(licenseId: string): Promise<FcmTokenDocument[]> {
    const snapshots = await getDatabase().collection(collectionName)
      .where("licenseId", "==", licenseId).get();
    return snapshots.docs.flatMap((snapshot) => tokenDocument(snapshot));
  }
}

export function deviceReference(token: string) {
  return getDatabase().collection(collectionName).doc(deviceId(token));
}

function deviceId(token: string): string {
  return createHash("sha256").update(token).digest("base64url");
}

function tokenDocument(snapshot: QueryDocumentSnapshot): FcmTokenDocument[] {
  const token = snapshot.data().token;
  if (typeof token !== "string" || token.length === 0) return [];
  return [{token, delete: async () => { await snapshot.ref.delete(); }}];
}
