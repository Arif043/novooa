import {type TeamContextStore} from "../repositories/team-context-store.js";
import {type TeamMembershipStore} from "../repositories/team-membership-store.js";
import {invalidTeamMember} from "./team-membership-errors.js";

export class RemoveTeamMemberUseCase {
  constructor(
    private readonly teamContext: TeamContextStore,
    private readonly membership: TeamMembershipStore,
  ) {}

  async execute(input: {ownerUid: string; uid: string}): Promise<{uid: string}> {
    if (input.uid === input.ownerUid) {
      throw invalidTeamMember("Owner cannot be removed.");
    }
    const teamId = await this.teamContext.currentTeamIdForUid(input.ownerUid);
    await this.membership.removeMember({teamId, uid: input.uid});
    return {uid: input.uid};
  }
}
