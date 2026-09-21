export type MailConnectorProvider = "microsoftGraph";

export type MailConnectorDeliveryTarget = "cloud" | "localRuntime";

export type MailConnectorStatus =
  | "active"
  | "reauthorizationRequired"
  | "disconnected";

export type MailConnector = {
  id: string;
  teamId: string;
  createdByUid: string;
  provider: MailConnectorProvider;
  deliveryTarget: MailConnectorDeliveryTarget;
  runtimeLicenseId: string | null;
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
