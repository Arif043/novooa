import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth, UserRecord} from "firebase-admin/auth";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "genkit";

if (getApps().length === 0) {
  initializeApp();
}

const addTeamMemberInputSchema = z.object({
  identifier: z.string().min(1).max(254),
});

const removeTeamMemberInputSchema = z.object({
  uid: z.string().min(1).max(128),
});

type AddTeamMemberInput = z.infer<typeof addTeamMemberInputSchema>;
type RemoveTeamMemberInput = z.infer<typeof removeTeamMemberInputSchema>;

export const addTeamMemberFlow = onCall(async (request) => {
  const ownerUid = authenticatedUid(request.auth?.uid);
  const input = addInputFrom(request.data);
  const targetUser = await userFor(input.identifier.trim());
  if (targetUser.uid === ownerUid) {
    throw new HttpsError("invalid-argument", "Owner is already a member.");
  }
  const teamId = personalTeamId(ownerUid);
  await ensurePersonalTeam(teamId, ownerUid);
  await getFirestore()
    .collection("teams")
    .doc(teamId)
    .collection("members")
    .doc(targetUser.uid)
    .set(memberDocument(targetUser.uid, "member"), {merge: true});
  return {uid: targetUser.uid};
});

export const removeTeamMemberFlow = onCall(async (request) => {
  const ownerUid = authenticatedUid(request.auth?.uid);
  const input = removeInputFrom(request.data);
  if (input.uid === ownerUid) {
    throw new HttpsError("invalid-argument", "Owner cannot be removed.");
  }
  const teamId = personalTeamId(ownerUid);
  await ensurePersonalTeam(teamId, ownerUid);
  await getFirestore()
    .collection("teams")
    .doc(teamId)
    .collection("members")
    .doc(input.uid)
    .delete();
  return {uid: input.uid};
});

function authenticatedUid(uid: string | undefined): string {
  if (!uid) throw new HttpsError("unauthenticated", "Auth is required.");
  return uid;
}

function addInputFrom(data: unknown): AddTeamMemberInput {
  try {
    return addTeamMemberInputSchema.parse(data);
  } catch {
    throw new HttpsError("invalid-argument", "Invalid member input.");
  }
}

function removeInputFrom(data: unknown): RemoveTeamMemberInput {
  try {
    return removeTeamMemberInputSchema.parse(data);
  } catch {
    throw new HttpsError("invalid-argument", "Invalid member input.");
  }
}

async function userFor(identifier: string): Promise<UserRecord> {
  try {
    if (identifier.includes("@")) {
      return await getAuth().getUserByEmail(identifier);
    }
    return await getAuth().getUser(identifier);
  } catch {
    throw new HttpsError("not-found", "User was not found.");
  }
}

async function ensurePersonalTeam(teamId: string, ownerUid: string): Promise<void> {
  const firestore = getFirestore();
  const batch = firestore.batch();
  const teamReference = firestore.collection("teams").doc(teamId);
  batch.set(
    teamReference,
    {
      ownerUid,
      name: "Persönlicher Arbeitsbereich",
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  batch.set(
    teamReference.collection("members").doc(ownerUid),
    memberDocument(ownerUid, "owner"),
    {merge: true},
  );
  await batch.commit();
}

function memberDocument(uid: string, role: "owner" | "member") {
  return {uid, role, joinedAt: FieldValue.serverTimestamp()};
}

function personalTeamId(uid: string): string {
  return `personal_${uid}`;
}
