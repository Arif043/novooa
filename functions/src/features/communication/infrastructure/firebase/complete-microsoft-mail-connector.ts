import {onRequest} from "firebase-functions/v2/https";
import {type Request, type Response} from "express";
import {logException, logInfo} from "../../../../shared/logging/logger.js";
import {sendOAuthResultPage} from "../../../../shared/firebase/oauth-result-page.js";
import {completeMailConnectorAuthorization} from
  "../../domain/usecases/complete-mail-connector-authorization.js";
import {FirestoreMailConnectorRepository} from
  "../firebase/firestore-mail-connector-repository.js";
import {
  mailConnectorCipher,
  mailConnectorEncryptionKey,
  microsoftGraphClientSecret,
  microsoftGraphProvider,
} from "../microsoft_graph/microsoft-graph-config.js";
import {authorizationId} from "../../../../shared/security/oauth-pkce.js";
import {subscriptionClientState} from "../microsoft_graph/microsoft-oauth-proof.js";

export const completeMicrosoftMailConnector = onRequest(
  {
    invoker: "public",
    secrets: [microsoftGraphClientSecret, mailConnectorEncryptionKey],
  },
  async (request, response) => {
    if (request.method !== "GET") {
      methodNotAllowed(response);
      return;
    }
    const error = queryValue(request.query.error);
    if (error) {
      authorizationFailed(response, error);
      return;
    }
    try {
      const connector = await completeConnector(request);
      logInfo("mail_connector.connected", {teamId: connector.teamId, connectorId: connector.id});
      authorizationSucceeded(response, connector.emailAddress);
    } catch (error) {
      logException("mail_connector.authorization_failed", error);
      authorizationFailed(response, "Die Postfach-Verbindung konnte nicht eingerichtet werden.");
    }
  },
);

async function completeConnector(request: Request) {
  const state = requiredQueryValue(request.query.state, "state");
  const code = requiredQueryValue(request.query.code, "code");
  return completeMailConnectorAuthorization({
    authorizationId: state,
    authorizationCode: code,
    connectorId: authorizationId(),
    subscriptionClientState: subscriptionClientState(),
    repository: new FirestoreMailConnectorRepository(mailConnectorCipher()),
    provider: microsoftGraphProvider(),
    now: new Date(),
  });
}

function methodNotAllowed(response: Response): void {
  response.status(405).send("Method Not Allowed");
}

function authorizationSucceeded(response: Response, emailAddress: string): void {
  sendOAuthResultPage(response, {ok: true, title: "Postfach verbunden", message: `${emailAddress} ist jetzt mit novooa verbunden.`});
}

function authorizationFailed(response: Response, message: string): void {
  sendOAuthResultPage(response, {ok: false, title: "Verbindung fehlgeschlagen", message});
}

function requiredQueryValue(value: unknown, name: string): string {
  const normalized = queryValue(value);
  if (!normalized) throw new Error(`Missing OAuth ${name}.`);
  return normalized;
}

function queryValue(value: unknown): string {
  return typeof value === "string" ? value : "";
}
