import {FieldValue} from "firebase-admin/firestore";
import {
  type AcceptTeamInvitationInput,
  type InviteTeamMemberInput,
  type RejectTeamInvitationInput,
  type RemoveTeamMemberInput,
  type TeamMembershipStore,
} from "../../domain/repositories/team-membership-store.js";
import {type TeamInvitation} from "../../domain/entities/team.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {memberDocument} from "./firestore-team-context-store.js";

export class FirestoreTeamMembershipStore implements TeamMembershipStore {
  async teamName(teamId: string): Promise<string> {
    const team = await teamReference(teamId).get();
    return stringFrom(team.data()?.name, "Team");
  }

  async isMember(teamId: string, uid: string): Promise<boolean> {
    const member = await teamReference(teamId).collection("members").doc(uid).get();
    return member.exists;
  }

  async inviteMember(input: InviteTeamMemberInput): Promise<string> {
    const notificationId = `teamInvitation_${input.teamId}`;
    await notificationReference(input.inviteeUid, notificationId).set(
      invitationDocument(input),
      {merge: true},
    );
    return notificationId;
  }

  async removeMember(input: RemoveTeamMemberInput): Promise<void> {
    const batch = getDatabase().batch();
    batch.delete(teamReference(input.teamId).collection("members").doc(input.uid));
    batch.set(userReference(input.uid), removedTeamDocument(), {merge: true});
    await batch.commit();
  }

  async invitationFor(uid: string, invitationId: string): Promise<TeamInvitation> {
    const notification = await notificationReference(uid, invitationId).get();
    const data = notification.data() ?? {};
    return {
      id: invitationId,
      teamId: stringFrom(data.teamId, ""),
      status: invitationStatusFrom(data),
    };
  }

  async acceptInvitation(input: AcceptTeamInvitationInput): Promise<void> {
    const previousTeamId = await currentTeamId(input.uid);
    const batch = getDatabase().batch();
    if (previousTeamId && previousTeamId !== input.teamId) {
      batch.delete(teamReference(previousTeamId).collection("members").doc(input.uid));
    }
    batch.set(
      teamReference(input.teamId).collection("members").doc(input.uid),
      memberDocument(input.uid, "member"),
      {merge: true},
    );
    batch.set(userReference(input.uid), activeTeamDocument(input.teamId), {
      merge: true,
    });
    batch.set(
      notificationReference(input.uid, input.invitationId),
      actionedDocument("accepted"),
      {merge: true},
    );
    await batch.commit();
  }

  async rejectInvitation(input: RejectTeamInvitationInput): Promise<void> {
    await notificationReference(input.uid, input.invitationId).set(
      actionedDocument("rejected"),
      {merge: true},
    );
  }
}

function invitationDocument(input: InviteTeamMemberInput) {
  return {
    type: "teamInvitation",
    status: "pending",
    title: "Teameinladung",
    message: `Du wurdest in "${input.teamName}" eingeladen.`,
    teamId: input.teamId,
    teamName: input.teamName,
    inviterUid: input.inviterUid,
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

function removedTeamDocument() {
  return {teamId: FieldValue.delete(), updatedAt: FieldValue.serverTimestamp()};
}

function activeTeamDocument(teamId: string) {
  return {teamId, updatedAt: FieldValue.serverTimestamp()};
}

async function currentTeamId(uid: string): Promise<string> {
  const user = await userReference(uid).get();
  return stringFrom(user.data()?.teamId, "");
}

function invitationStatusFrom(data: Record<string, unknown>) {
  if (data.type !== "teamInvitation") return "rejected";
  return data.status === "pending" ? "pending" : "rejected";
}

function notificationReference(uid: string, notificationId: string) {
  return userReference(uid).collection("notifications").doc(notificationId);
}

function userReference(uid: string) {
  return getDatabase().collection("users").doc(uid);
}

function teamReference(teamId: string) {
  return getDatabase().collection("teams").doc(teamId);
}

function stringFrom(value: unknown, fallback: string) {
  return typeof value === "string" && value.trim() ? value : fallback;
}
