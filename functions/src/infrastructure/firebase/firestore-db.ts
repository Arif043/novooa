import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

export function getDatabase() {
  initializeAdminApp();
  return getFirestore();
}

export function initializeAdminApp(): void {
  if (getApps().length === 0) initializeApp();
}
