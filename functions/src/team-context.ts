import {getApps, initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";

export async function currentTeamIdForUid(uid: string): Promise<string> {
  initializeAdminApp();
  const firestore = getFirestore();
  const userReference = firestore.collection("users").doc(uid);
  const snapshot = await userReference.get();
  const existingTeamId = teamIdFromUser(snapshot.data());
  if (existingTeamId) return existingTeamId;
  const teamReference = firestore.collection("teams").doc();
  const batch = firestore.batch();
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

export function initializeAdminApp(): void {
  if (getApps().length === 0) initializeApp();
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
