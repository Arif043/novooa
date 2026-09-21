import {
  type MailConnectorDeliveryTarget,
  type MailConnectorProvider,
} from "./mail-connector.js";

export type MailConnectorAuthorization = {
  id: string;
  teamId: string;
  uid: string;
  provider: MailConnectorProvider;
  deliveryTarget: MailConnectorDeliveryTarget;
  runtimeLicenseId: string | null;
  codeVerifier: string;
  expiresAt: Date;
};
