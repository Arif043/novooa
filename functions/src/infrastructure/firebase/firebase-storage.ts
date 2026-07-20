import {getStorage} from "firebase-admin/storage";
import {initializeAdminApp} from "./firestore-db.js";

export function getDefaultStorageBucket() {
  initializeAdminApp();
  return getStorage().bucket();
}
