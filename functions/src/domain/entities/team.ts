export type TeamUser = {
  uid: string;
  email?: string;
};

export type TeamInvitationStatus = "pending" | "accepted" | "rejected";

export type TeamInvitation = {
  id: string;
  teamId: string;
  status: TeamInvitationStatus;
};
