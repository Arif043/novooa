import {type TeamMemberDirectory} from "../repositories/team-member-directory.js";
import {type TeamMembershipStore} from "../repositories/team-membership-store.js";
import {type TeamContextStore} from "../repositories/team-context-store.js";
import {invalidTeamMember} from "./team-membership-errors.js";

export type AddTeamMemberOutput = {
  uid: string;
  status?: "alreadyMember";
  notificationId?: string;
};

export class AddTeamMemberUseCase {
  constructor(
    private readonly directory: TeamMemberDirectory,
    private readonly teamContext: TeamContextStore,
    private readonly membership: TeamMembershipStore,
  ) {}

  async execute(input: {
    ownerUid: string;
    identifier: string;
  }): Promise<AddTeamMemberOutput> {
    const target = await this.directory.userFor(input.identifier.trim());
    if (target.uid === input.ownerUid) {
      throw invalidTeamMember("Owner is already a member.");
    }
    const teamId = await this.teamContext.currentTeamIdForUid(input.ownerUid);
    if (await this.membership.isMember(teamId, target.uid)) {
      return {uid: target.uid, status: "alreadyMember"};
    }
    return this.inviteTarget(input.ownerUid, teamId, target.uid);
  }

  private async inviteTarget(
    ownerUid: string,
    teamId: string,
    targetUid: string,
  ): Promise<AddTeamMemberOutput> {
    const teamName = await this.membership.teamName(teamId);
    const notificationId = await this.membership.inviteMember({
      teamId,
      teamName,
      inviterUid: ownerUid,
      inviteeUid: targetUid,
    });
    return {uid: targetUid, notificationId};
  }
}
