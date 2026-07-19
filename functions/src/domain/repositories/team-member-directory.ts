import {type TeamUser} from "../entities/team.js";

export interface TeamMemberDirectory {
  userFor(identifier: string): Promise<TeamUser>;
}
