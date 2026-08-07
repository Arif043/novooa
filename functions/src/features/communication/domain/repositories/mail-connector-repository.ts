import {
  type MailConnector,
  type MailConnectorCredentials,
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

  updateCredentials(input: {
    connectorId: string;
    teamId: string;
    credentials: MailConnectorCredentials;
  }): Promise<void>;
}
