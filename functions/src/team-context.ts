import {
  FirestoreTeamContextStore,
  memberDocument,
  teamDocument,
} from "./infrastructure/firebase/firestore-team-context-store.js";
import {initializeAdminApp} from "./infrastructure/firebase/firestore-db.js";

const defaultTeamContextStore = new FirestoreTeamContextStore();

export {initializeAdminApp, memberDocument, teamDocument};

export function currentTeamIdForUid(uid: string): Promise<string> {
  return defaultTeamContextStore.currentTeamIdForUid(uid);
}
