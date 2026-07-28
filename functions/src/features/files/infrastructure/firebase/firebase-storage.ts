import {getStorage} from "firebase-admin/storage";
import {initializeAdminApp} from "../../../../shared/firebase/firestore-db.js";

export function getDefaultStorageBucket() {
  initializeAdminApp();
  return getStorage().bucket();
}
