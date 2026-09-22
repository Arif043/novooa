import {type TeamInvitation} from "../entities/team.js";

export type InviteTeamMemberInput = {
  teamId: string;
  teamName: string;
  inviterUid: string;
  inviteeUid: string;
};

export type RemoveTeamMemberInput = {
  teamId: string;
  uid: string;
};

export type AcceptTeamInvitationInput = {
  uid: string;
  invitationId: string;
  teamId: string;
};

export type RejectTeamInvitationInput = {
  uid: string;
  invitationId: string;
};

export interface TeamMembershipStore {
  teamName(teamId: string): Promise<string>;
  isMember(teamId: string, uid: string): Promise<boolean>;
  memberUids(teamId: string): Promise<string[]>;
  inviteMember(input: InviteTeamMemberInput): Promise<string>;
  removeMember(input: RemoveTeamMemberInput): Promise<void>;
  invitationFor(uid: string, invitationId: string): Promise<TeamInvitation>;
  acceptInvitation(input: AcceptTeamInvitationInput): Promise<void>;
  rejectInvitation(input: RejectTeamInvitationInput): Promise<void>;
}
