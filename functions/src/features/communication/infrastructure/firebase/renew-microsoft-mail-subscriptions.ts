import {onSchedule} from "firebase-functions/v2/scheduler";
import {logException, logInfo} from "../../../../shared/logging/logger.js";
import {MailReauthorizationRequiredError} from "../../domain/services/mail-connector-token-service.js";
import {renewMailConnectorSubscription} from "../../domain/usecases/renew-mail-connector-subscription.js";
import {FirestoreMailConnectorRepository} from "../firebase/firestore-mail-connector-repository.js";
import {
  mailConnectorCipher,
  mailConnectorEncryptionKey,
  microsoftGraphClientSecret,
  mailTokenService,
  microsoftGraphProvider,
} from "../microsoft_graph/microsoft-graph-config.js";

export const renewMicrosoftMailSubscriptions = onSchedule(
  {
    schedule: "every 6 hours",
    timeZone: "Europe/Berlin",
    maxInstances: 1,
    secrets: [microsoftGraphClientSecret, mailConnectorEncryptionKey],
  },
  () => renewDueSubscriptions(),
);

async function renewDueSubscriptions(): Promise<void> {
  const repository = new FirestoreMailConnectorRepository(mailConnectorCipher());
  const connectors = await repository.listConnectorsExpiringBefore(expiryHorizon());
  for (const connection of connectors) await renewConnection(connection, repository);
  logInfo("microsoft_graph.subscriptions_renewed", {count: connectors.length});
}

async function renewConnection(
  connection: Awaited<ReturnType<FirestoreMailConnectorRepository["listConnectorsExpiringBefore"]>>[number],
  repository: FirestoreMailConnectorRepository,
): Promise<void> {
  try {
    const provider = microsoftGraphProvider();
    const outcome = await renewMailConnectorSubscription({
      ...connection,
      repository,
      provider,
      tokens: mailTokenService(repository, provider),
    });
    if (outcome === "recreated") {
      logInfo("microsoft_graph.subscription_recreated", {
        connectorId: connection.connector.id,
        teamId: connection.connector.teamId,
      });
    }
  } catch (error) {
    if (error instanceof MailReauthorizationRequiredError) {
      logInfo("microsoft_graph.connector_needs_reauthorization", {
        connectorId: connection.connector.id,
        teamId: connection.connector.teamId,
      });
      return;
    }
    logException("microsoft_graph.subscription_renewal_failed", error, {
      connectorId: connection.connector.id,
      teamId: connection.connector.teamId,
    });
  }
}

function expiryHorizon(): Date {
  return new Date(Date.now() + 12 * 60 * 60 * 1000);
}
