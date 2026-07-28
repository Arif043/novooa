import {type TeamMembershipStore} from "../repositories/team-membership-store.js";
import {invalidInvitationState} from "./team-membership-errors.js";

export class AcceptTeamInvitationUseCase {
  constructor(private readonly membership: TeamMembershipStore) {}

  async execute(input: {uid: string; notificationId: string}) {
    const invitation = await this.membership.invitationFor(
      input.uid,
      input.notificationId,
    );
    if (invitation.status !== "pending" || invitation.teamId.length === 0) {
      throw invalidInvitationState("Invitation is not pending.");
    }
    await this.membership.acceptInvitation({
      uid: input.uid,
      invitationId: invitation.id,
      teamId: invitation.teamId,
    });
    return {notificationId: input.notificationId, status: "accepted" as const};
  }
}
