import {Timestamp, type DocumentData} from "firebase-admin/firestore";
import {
  type MailConnector,
  type MailConnectorCredentials,
  type MailConnectorStatus,
} from "../../domain/entities/mail-connector.js";
import {type MailConnectorAuthorization} from
  "../../domain/entities/mail-connector-authorization.js";
import {type MailConnectorRepository} from
  "../../domain/repositories/mail-connector-repository.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {signalRuntimeConnectorsChanged} from "./runtime-connectors-signal.js";
import {CredentialCipher} from "../security/credential-cipher.js";
import {
  authorizationDocument,
  authorizationFrom,
  connectorDocument,
  connectorFrom,
  credentialsDocument,
  credentialsFrom,
} from "./firestore-mail-connector-documents.js";

export class FirestoreMailConnectorRepository implements MailConnectorRepository {
  constructor(cipher: CredentialCipher) {
    this.#cipher = cipher;
  }

  readonly #cipher: CredentialCipher;

  async createAuthorization(input: MailConnectorAuthorization): Promise<void> {
    await authorizationReference(input.teamId, input.id).set(authorizationDocument(input));
  }

  async consumeAuthorization(id: string): Promise<MailConnectorAuthorization | null> {
    const snapshot = await getDatabase().collectionGroup("mailConnectorAuthorizations")
      .where("id", "==", id).limit(1).get();
    if (snapshot.empty) return null;
    return this.#consumeAuthorization(snapshot.docs[0]);
  }

  async createConnector(input: {
    connector: MailConnector;
    credentials: MailConnectorCredentials;
  }): Promise<void> {
    const batch = getDatabase().batch();
    batch.set(connectorReference(input.connector), connectorDocument(input.connector));
    batch.set(credentialsReference(input.connector), credentialsDocument(input.credentials, this.#cipher));
    await batch.commit();
    await signalLocalRuntime(input.connector);
  }

  async loadConnectorBySubscription(subscriptionId: string) {
    const snapshot = await getDatabase().collectionGroup("mailConnectors")
      .where("subscriptionId", "==", subscriptionId).limit(1).get();
    if (snapshot.empty) return null;
    return this.#connectorWithCredentials(snapshot.docs[0]);
  }

  async listConnectorsForRuntimeLicense(input: {teamId: string; runtimeLicenseId: string}) {
    const snapshot = await getDatabase().collection("teams").doc(input.teamId)
      .collection("mailConnectors")
      .where("runtimeLicenseId", "==", input.runtimeLicenseId).get();
    return snapshot.docs
      .map((document) => connectorFrom(document.data(), document.id))
      .filter((connector) => connector.deliveryTarget === "localRuntime");
  }

  async findConnectorByEmailAddress(input: {teamId: string; emailAddress: string}) {
    const snapshot = await getDatabase().collection("teams").doc(input.teamId)
      .collection("mailConnectors")
      .where("emailAddress", "==", input.emailAddress).limit(1).get();
    if (snapshot.empty) return null;
    return connectorFrom(snapshot.docs[0].data(), snapshot.docs[0].id);
  }

  async loadConnector(input: {teamId: string; connectorId: string}) {
    const snapshot = await connectorReferenceById(input.teamId, input.connectorId).get();
    if (!snapshot.exists) return null;
    return this.#connectorWithCredentials(snapshot);
  }

  async listConnectorsExpiringBefore(expiresBefore: Date) {
    const snapshot = await getDatabase().collectionGroup("mailConnectors")
      .where("status", "==", "active")
      .where("subscriptionExpiresAt", "<=", Timestamp.fromDate(expiresBefore))
      .get();
    const values = await Promise.all(
      snapshot.docs.map((document) => this.#connectorWithCredentials(document)),
    );
    return values.flatMap((value) => value ? [value] : []);
  }

  async updateSubscription(input: {
    connectorId: string;
    teamId: string;
    subscriptionId: string;
    subscriptionExpiresAt: Date;
  }): Promise<void> {
    await connectorReferenceById(input.teamId, input.connectorId).update({
      subscriptionId: input.subscriptionId,
      subscriptionExpiresAt: Timestamp.fromDate(input.subscriptionExpiresAt),
      updatedAt: Timestamp.now(),
    });
  }

  async updateStatus(input: {
    connectorId: string;
    teamId: string;
    status: MailConnectorStatus;
  }): Promise<void> {
    const reference = connectorReferenceById(input.teamId, input.connectorId);
    await reference.update({status: input.status, updatedAt: Timestamp.now()});
    const snapshot = await reference.get();
    if (snapshot.exists) await signalLocalRuntime(connectorFrom(snapshot.data() ?? {}, snapshot.id));
  }

  async updateCredentials(input: {
    connectorId: string;
    teamId: string;
    credentials: MailConnectorCredentials;
  }): Promise<void> {
    await credentialsReferenceById(input.teamId, input.connectorId).set(
      credentialsDocument(input.credentials, this.#cipher),
      {merge: true},
    );
  }

  async #consumeAuthorization(
    document: FirebaseFirestore.QueryDocumentSnapshot<DocumentData>,
  ): Promise<MailConnectorAuthorization | null> {
    const reference = document.ref;
    return getDatabase().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      if (!snapshot.exists) return null;
      transaction.delete(reference);
      return authorizationFrom(snapshot.data() ?? {});
    });
  }

  async #connectorWithCredentials(
    document: FirebaseFirestore.DocumentSnapshot<DocumentData>,
  ): Promise<{connector: MailConnector; credentials: MailConnectorCredentials} | null> {
    const connector = connectorFrom(document.data() ?? {}, document.id);
    const snapshot = await credentialsReference(connector).get();
    if (!snapshot.exists) return null;
    return {connector, credentials: credentialsFrom(snapshot.data() ?? {}, this.#cipher)};
  }
}

/** Nur Postfächer einer lokalen Runtime haben jemanden, der die Änderung wissen muss. */
async function signalLocalRuntime(connector: MailConnector): Promise<void> {
  if (connector.deliveryTarget !== "localRuntime" || connector.runtimeLicenseId === null) return;
  await signalRuntimeConnectorsChanged(connector.runtimeLicenseId);
}

function authorizationReference(teamId: string, id: string) {
  return getDatabase().collection("teams").doc(teamId)
    .collection("mailConnectorAuthorizations").doc(id);
}

function connectorReference(connector: MailConnector) {
  return connectorReferenceById(connector.teamId, connector.id);
}

function connectorReferenceById(teamId: string, connectorId: string) {
  return getDatabase().collection("teams").doc(teamId)
    .collection("mailConnectors").doc(connectorId);
}

function credentialsReference(connector: MailConnector) {
  return credentialsReferenceById(connector.teamId, connector.id);
}

function credentialsReferenceById(teamId: string, connectorId: string) {
  return getDatabase().collection("teams").doc(teamId)
    .collection("mailConnectorCredentials").doc(connectorId);
}
