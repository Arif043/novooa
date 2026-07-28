import {type TeamMembershipStore} from "../repositories/team-membership-store.js";
import {invalidInvitationState} from "./team-membership-errors.js";

export class RejectTeamInvitationUseCase {
  constructor(private readonly membership: TeamMembershipStore) {}

  async execute(input: {uid: string; notificationId: string}) {
    const invitation = await this.membership.invitationFor(
      input.uid,
      input.notificationId,
    );
    if (invitation.status !== "pending") {
      throw invalidInvitationState("Invitation is not pending.");
    }
    await this.membership.rejectInvitation({
      uid: input.uid,
      invitationId: invitation.id,
    });
    return {notificationId: input.notificationId, status: "rejected" as const};
  }
}
