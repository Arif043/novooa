import {FieldValue} from "firebase-admin/firestore";
import {getDatabase} from "./task-runner/stores/firestore-db.js";
import {type TeamContextStore} from "./team-context-store.js";

export class FirestoreTeamContextStore implements TeamContextStore {
  async currentTeamIdForUid(uid: string): Promise<string> {
    const userReference = getDatabase().collection("users").doc(uid);
    const snapshot = await userReference.get();
    const existingTeamId = teamIdFromUser(snapshot.data());
    if (existingTeamId) return existingTeamId;
    const teamReference = getDatabase().collection("teams").doc();
    const batch = getDatabase().batch();
    batch.set(teamReference, teamDocument(uid));
    batch.set(
      teamReference.collection("members").doc(uid),
      memberDocument(uid, "owner"),
    );
    batch.set(
      userReference,
      {teamId: teamReference.id, updatedAt: FieldValue.serverTimestamp()},
      {merge: true},
    );
    await batch.commit();
    return teamReference.id;
  }
}

export function teamDocument(ownerUid: string) {
  return {
    ownerUid,
    name: "Persönlicher Arbeitsbereich",
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export function memberDocument(uid: string, role: "owner" | "member") {
  return {uid, role, joinedAt: FieldValue.serverTimestamp()};
}

function teamIdFromUser(data: Record<string, unknown> | undefined) {
  const teamId = data?.teamId;
  return typeof teamId === "string" && teamId.length > 0 ? teamId : null;
}
