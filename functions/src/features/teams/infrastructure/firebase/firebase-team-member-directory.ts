import {getAuth} from "firebase-admin/auth";
import {type TeamUser} from "../../domain/entities/team.js";
import {
  teamUserNotFound,
} from "../../domain/usecases/team-membership-errors.js";
import {
  type TeamMemberDirectory,
} from "../../domain/repositories/team-member-directory.js";

export class FirebaseTeamMemberDirectory implements TeamMemberDirectory {
  async userFor(identifier: string): Promise<TeamUser> {
    try {
      const user = identifier.includes("@")
        ? await getAuth().getUserByEmail(identifier)
        : await getAuth().getUser(identifier);
      return {uid: user.uid, email: user.email};
    } catch {
      throw teamUserNotFound("User was not found.");
    }
  }
}
