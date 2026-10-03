import {FieldValue} from "firebase-admin/firestore";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";

/**
 * Meldet der lokalen Runtime, dass sich ihre Postfachliste in der Cloud
 * geändert hat. Sie hört auf dasselbe Wake-up-Dokument wie für neue Mails;
 * nur die Revision unterscheidet, was sich geändert hat. Inhalte stehen
 * nicht im Dokument: Die Runtime lädt die Liste anschließend selbst.
 */
export async function signalRuntimeConnectorsChanged(licenseId: string): Promise<void> {
  await getDatabase().collection("localRuntimeWakeups").doc(licenseId).set({
    licenseId,
    connectorsRevision: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}
