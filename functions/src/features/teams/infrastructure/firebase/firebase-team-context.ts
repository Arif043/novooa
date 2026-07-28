import {
  FirestoreTeamContextStore,
  memberDocument,
  teamDocument,
} from "./firestore-team-context-store.js";
import {initializeAdminApp} from "../../../../shared/firebase/firestore-db.js";

const defaultTeamContextStore = new FirestoreTeamContextStore();

export {initializeAdminApp, memberDocument, teamDocument};

export function currentTeamIdForUid(uid: string): Promise<string> {
  return defaultTeamContextStore.currentTeamIdForUid(uid);
}
