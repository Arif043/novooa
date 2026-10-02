import {type MailConnector, type MailConnectorStatus} from "./mail-connector.js";

/** Was die lokale Runtime von einem Postfach erfährt: genug zum Anzeigen, nie Zugangsdaten. */
export type MailConnectorSummary = {
  id: string;
  teamId: string;
  emailAddress: string;
  displayName: string;
  status: MailConnectorStatus;
};

export function mailConnectorSummaryFrom(connector: MailConnector): MailConnectorSummary {
  return {
    id: connector.id, teamId: connector.teamId, emailAddress: connector.emailAddress,
    displayName: connector.displayName, status: connector.status,
  };
}
