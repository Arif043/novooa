export type MailConnectorProvider = "microsoftGraph";

export type MailConnectorStatus =
  | "active"
  | "reauthorizationRequired"
  | "disconnected";

export type MailConnector = {
  id: string;
  teamId: string;
  createdByUid: string;
  provider: MailConnectorProvider;
  emailAddress: string;
  displayName: string;
  status: MailConnectorStatus;
  subscriptionId: string | null;
  subscriptionExpiresAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

export type MailConnectorCredentials = {
  refreshToken: string;
  subscriptionClientState: string;
};
