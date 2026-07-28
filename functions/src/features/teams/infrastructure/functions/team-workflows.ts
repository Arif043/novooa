import {HttpsError, onCall} from "firebase-functions/v2/https";
import {z} from "genkit";
import {AddTeamMemberUseCase} from "../../domain/usecases/add-team-member.js";
import {RemoveTeamMemberUseCase} from "../../domain/usecases/remove-team-member.js";
import {
  AcceptTeamInvitationUseCase,
} from "../../domain/usecases/accept-team-invitation.js";
import {
  RejectTeamInvitationUseCase,
} from "../../domain/usecases/reject-team-invitation.js";
import {
  TeamMembershipError,
} from "../../domain/usecases/team-membership-errors.js";
import {FirebaseTeamMemberDirectory} from
  "../firebase/firebase-team-member-directory.js";
import {FirestoreTeamContextStore} from
  "../firebase/firestore-team-context-store.js";
import {FirestoreTeamMembershipStore} from
  "../firebase/firestore-team-membership-store.js";
import {logException} from "../../../../shared/logging/logger.js";

const addTeamMemberInputSchema = z.object({
  identifier: z.string().min(1).max(254),
});

const removeTeamMemberInputSchema = z.object({
  uid: z.string().min(1).max(128),
});

const invitationActionInputSchema = z.object({
  notificationId: z.string().min(1).max(160),
});

export const addTeamMemberFlow = onCall(async (request) =>
  runTeamAction("team_member.add_failed", async () => {
    const uid = authenticatedUid(request.auth?.uid);
    const input = addInputFrom(request.data);
    return teamUseCases().add.execute({ownerUid: uid, ...input});
  }));

export const removeTeamMemberFlow = onCall(async (request) =>
  runTeamAction("team_member.remove_failed", async () => {
    const ownerUid = authenticatedUid(request.auth?.uid);
    const input = removeInputFrom(request.data);
    return teamUseCases().remove.execute({ownerUid, uid: input.uid});
  }));

export const acceptTeamInvitationFlow = onCall(async (request) =>
  runTeamAction("team_invitation.accept_failed", async () => {
    const uid = authenticatedUid(request.auth?.uid);
    const input = invitationActionInputFrom(request.data);
    return teamUseCases().accept.execute({uid, ...input});
  }));

export const rejectTeamInvitationFlow = onCall(async (request) =>
  runTeamAction("team_invitation.reject_failed", async () => {
    const uid = authenticatedUid(request.auth?.uid);
    const input = invitationActionInputFrom(request.data);
    return teamUseCases().reject.execute({uid, ...input});
  }));

function teamUseCases() {
  const membership = new FirestoreTeamMembershipStore();
  return {
    add: new AddTeamMemberUseCase(
      new FirebaseTeamMemberDirectory(),
      new FirestoreTeamContextStore(),
      membership,
    ),
    remove: new RemoveTeamMemberUseCase(
      new FirestoreTeamContextStore(),
      membership,
    ),
    accept: new AcceptTeamInvitationUseCase(membership),
    reject: new RejectTeamInvitationUseCase(membership),
  };
}

function authenticatedUid(uid: string | undefined): string {
  if (!uid) throw new HttpsError("unauthenticated", "Auth ist erforderlich.");
  return uid;
}

async function runTeamAction<T>(
  event: string,
  action: () => Promise<T>,
): Promise<T> {
  try {
    return await action();
  } catch (error) {
    logException(event, error);
    throw httpsErrorFrom(error);
  }
}

function addInputFrom(data: unknown) {
  return parsedInput(addTeamMemberInputSchema, data);
}

function removeInputFrom(data: unknown) {
  return parsedInput(removeTeamMemberInputSchema, data);
}

function invitationActionInputFrom(data: unknown) {
  return parsedInput(invitationActionInputSchema, data);
}

function parsedInput<T>(schema: z.ZodType<T>, data: unknown): T {
  try {
    return schema.parse(data);
  } catch {
    throw new HttpsError("invalid-argument", "Ungültige Eingabe.");
  }
}

function httpsErrorFrom(error: unknown): HttpsError {
  if (error instanceof HttpsError) return error;
  if (error instanceof TeamMembershipError) {
    return new HttpsError(error.code, error.message);
  }
  return new HttpsError("internal", "Teamaktion konnte nicht ausgeführt werden.");
}
