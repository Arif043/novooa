import {getApp, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

export function getDatabase() {
  initializeAdminApp();
  return getFirestore();
}

export function initializeAdminApp(): void {
  try {
    getApp();
  } catch {
    initializeApp();
  }
}
