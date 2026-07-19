export type TeamMembershipErrorCode =
  | "invalid-argument"
  | "not-found"
  | "failed-precondition";

export class TeamMembershipError extends Error {
  constructor(
    readonly code: TeamMembershipErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "TeamMembershipError";
  }
}

export function invalidTeamMember(message: string): TeamMembershipError {
  return new TeamMembershipError("invalid-argument", message);
}

export function teamUserNotFound(message: string): TeamMembershipError {
  return new TeamMembershipError("not-found", message);
}

export function invalidInvitationState(message: string): TeamMembershipError {
  return new TeamMembershipError("failed-precondition", message);
}
