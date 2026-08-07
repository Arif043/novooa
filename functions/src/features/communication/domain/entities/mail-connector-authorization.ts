import {type MailConnectorProvider} from "./mail-connector.js";

export type MailConnectorAuthorization = {
  id: string;
  teamId: string;
  uid: string;
  provider: MailConnectorProvider;
  codeVerifier: string;
  expiresAt: Date;
};
