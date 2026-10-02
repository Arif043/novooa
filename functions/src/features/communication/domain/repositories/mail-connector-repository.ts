import {
  type MailConnector,
  type MailConnectorCredentials,
  type MailConnectorStatus,
} from "../entities/mail-connector.js";
import {type MailConnectorAuthorization} from
  "../entities/mail-connector-authorization.js";

export interface MailConnectorRepository {
  createAuthorization(input: MailConnectorAuthorization): Promise<void>;

  consumeAuthorization(id: string): Promise<MailConnectorAuthorization | null>;

  createConnector(input: {
    connector: MailConnector;
    credentials: MailConnectorCredentials;
  }): Promise<void>;

  loadConnectorBySubscription(
    subscriptionId: string,
  ): Promise<{connector: MailConnector; credentials: MailConnectorCredentials} | null>;

  /** Alle Postfächer, die diese lokale Runtime (Lizenz) über das Relay nutzt. */
  listConnectorsForRuntimeLicense(input: {
    teamId: string;
    runtimeLicenseId: string;
  }): Promise<MailConnector[]>;

  /** Findet den Connector, der dieses Postfach im Team schon verbindet (zum erneuten Verbinden). */
  findConnectorByEmailAddress(input: {
    teamId: string;
    emailAddress: string;
  }): Promise<MailConnector | null>;

  loadConnector(input: {
    teamId: string;
    connectorId: string;
  }): Promise<{connector: MailConnector; credentials: MailConnectorCredentials} | null>;

  listConnectorsExpiringBefore(
    expiresBefore: Date,
  ): Promise<Array<{connector: MailConnector; credentials: MailConnectorCredentials}>>;

  updateSubscription(input: {
    connectorId: string;
    teamId: string;
    subscriptionId: string;
    subscriptionExpiresAt: Date;
  }): Promise<void>;

  updateStatus(input: {
    connectorId: string;
    teamId: string;
    status: MailConnectorStatus;
  }): Promise<void>;

  updateCredentials(input: {
    connectorId: string;
    teamId: string;
    credentials: MailConnectorCredentials;
  }): Promise<void>;
}
