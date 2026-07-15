import {getAuth, UserRecord} from "firebase-admin/auth";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "genkit";
import {currentTeamIdForUid, memberDocument} from "./team-context.js";

const addTeamMemberInputSchema = z.object({
  identifier: z.string().min(1).max(254),
});

const removeTeamMemberInputSchema = z.object({
  uid: z.string().min(1).max(128),
});

const invitationActionInputSchema = z.object({
  notificationId: z.string().min(1).max(160),
});

type AddTeamMemberInput = z.infer<typeof addTeamMemberInputSchema>;
type RemoveTeamMemberInput = z.infer<typeof removeTeamMemberInputSchema>;
type InvitationActionInput = z.infer<typeof invitationActionInputSchema>;

export const addTeamMemberFlow = onCall(async (request) => {
  const ownerUid = authenticatedUid(request.auth?.uid);
  const input = addInputFrom(request.data);
  const targetUser = await userFor(input.identifier.trim());
  if (targetUser.uid === ownerUid) {
    throw new HttpsError("invalid-argument", "Owner is already a member.");
  }
  const teamId = await currentTeamIdForUid(ownerUid);
  const firestore = getFirestore();
  const teamReference = firestore.collection("teams").doc(teamId);
  const member = await teamReference.collection("members").doc(targetUser.uid).get();
  if (member.exists) return {uid: targetUser.uid, status: "alreadyMember"};
  const team = await teamReference.get();
  const teamName = stringFrom(team.data()?.name, "Team");
  const notificationId = `teamInvitation_${teamId}`;
  await notificationReference(targetUser.uid, notificationId).set(
    invitationDocument({teamId, teamName, ownerUid}),
    {merge: true},
  );
  return {uid: targetUser.uid, notificationId};
});

export const removeTeamMemberFlow = onCall(async (request) => {
  const ownerUid = authenticatedUid(request.auth?.uid);
  const input = removeInputFrom(request.data);
  if (input.uid === ownerUid) {
    throw new HttpsError("invalid-argument", "Owner cannot be removed.");
  }
  const teamId = await currentTeamIdForUid(ownerUid);
  const firestore = getFirestore();
  const batch = firestore.batch();
  batch.delete(
    firestore.collection("teams").doc(teamId).collection("members").doc(input.uid),
  );
  batch.set(
    firestore.collection("users").doc(input.uid),
    {teamId: FieldValue.delete(), updatedAt: FieldValue.serverTimestamp()},
    {merge: true},
  );
  await batch.commit();
  return {uid: input.uid};
});

export const acceptTeamInvitationFlow = onCall(async (request) => {
  const uid = authenticatedUid(request.auth?.uid);
  const input = invitationActionInputFrom(request.data);
  const firestore = getFirestore();
  const notification = await notificationReference(uid, input.notificationId).get();
  const data = notification.data() ?? {};
  const teamId = stringFrom(data.teamId, "");
  if (!isPendingTeamInvitation(data) || !teamId) {
    throw new HttpsError("failed-precondition", "Invitation is not pending.");
  }
  const batch = firestore.batch();
  const userReference = firestore.collection("users").doc(uid);
  const user = await userReference.get();
  const previousTeamId = stringFrom(user.data()?.teamId, "");
  if (previousTeamId && previousTeamId !== teamId) {
    batch.delete(
      firestore
        .collection("teams")
        .doc(previousTeamId)
        .collection("members")
        .doc(uid),
    );
  }
  batch.set(
    firestore.collection("teams").doc(teamId).collection("members").doc(uid),
    memberDocument(uid, "member"),
    {merge: true},
  );
  batch.set(
    userReference,
    {teamId, updatedAt: FieldValue.serverTimestamp()},
    {merge: true},
  );
  batch.set(notification.ref, actionedDocument("accepted"), {merge: true});
  await batch.commit();
  return {notificationId: input.notificationId, status: "accepted"};
});

export const rejectTeamInvitationFlow = onCall(async (request) => {
  const uid = authenticatedUid(request.auth?.uid);
  const input = invitationActionInputFrom(request.data);
  const notification = await notificationReference(uid, input.notificationId).get();
  const data = notification.data() ?? {};
  if (!isPendingTeamInvitation(data)) {
    throw new HttpsError("failed-precondition", "Invitation is not pending.");
  }
  await notification.ref.set(actionedDocument("rejected"), {merge: true});
  return {notificationId: input.notificationId, status: "rejected"};
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

function invitationActionInputFrom(data: unknown): InvitationActionInput {
  try {
    return invitationActionInputSchema.parse(data);
  } catch {
    throw new HttpsError("invalid-argument", "Invalid invitation input.");
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

function notificationReference(uid: string, notificationId: string) {
  return getFirestore()
    .collection("users")
    .doc(uid)
    .collection("notifications")
    .doc(notificationId);
}

function invitationDocument(input: {
  teamId: string;
  teamName: string;
  ownerUid: string;
}) {
  return {
    type: "teamInvitation",
    status: "pending",
    title: "Teameinladung",
    message: `Du wurdest in "${input.teamName}" eingeladen.`,
    teamId: input.teamId,
    teamName: input.teamName,
    inviterUid: input.ownerUid,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function actionedDocument(status: "accepted" | "rejected") {
  return {
    status,
    updatedAt: FieldValue.serverTimestamp(),
    actionedAt: FieldValue.serverTimestamp(),
  };
}

function isPendingTeamInvitation(data: Record<string, unknown>) {
  return data.type === "teamInvitation" && data.status === "pending";
}

function stringFrom(value: unknown, fallback: string) {
  return typeof value === "string" && value.trim() ? value : fallback;
}
