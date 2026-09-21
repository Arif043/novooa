import {onRequest} from "firebase-functions/v2/https";
import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {FirebaseRuntimeRelayLicenseVerifier} from
  "../../../licensing/infrastructure/firebase/firebase-runtime-relay-license-verifier.js";
import {localRuntimeLicenseSigningKey} from
  "../../../licensing/infrastructure/firebase/local-runtime-license-signing-key.js";
import {RuntimeMailRelay} from "../../domain/usecases/runtime-mail-relay.js";
import {beginMailConnectorAuthorization} from
  "../../domain/usecases/begin-mail-connector-authorization.js";
import {logException, logInfo} from "../../../../shared/logging/logger.js";
import {FirestoreMailConnectorRepository} from "./firestore-mail-connector-repository.js";
import {FirestoreRuntimeMailRelayEventStore} from
  "./firestore-runtime-mail-relay-event-store.js";
import {
  mailConnectorCipher,
  mailConnectorEncryptionKey,
  microsoftGraphAuthorizationProvider,
  microsoftGraphClientSecret,
} from "../microsoft_graph/microsoft-graph-config.js";
import {authorizationCodeVerifier, authorizationId, codeChallenge} from
  "../microsoft_graph/microsoft-oauth-proof.js";
import {sendTeamMicrosoftGraphEmail} from
  "../microsoft_graph/team-microsoft-graph-email-sender.js";

const verifier = new FirebaseRuntimeRelayLicenseVerifier();
const relay = new RuntimeMailRelay(verifier, new FirestoreRuntimeMailRelayEventStore());

export const localRuntimeMailRelay = onRequest(
  {
    cors: false, invoker: "public",
    secrets: [localRuntimeLicenseSigningKey, mailConnectorEncryptionKey, microsoftGraphClientSecret],
  },
  async (request, response) => {
    if (request.method !== "POST") return void response.status(405).json({error: "Methode nicht erlaubt."});
    try {
      response.status(200).json(await execute(commandFrom(request.body)));
    } catch (error) {
      logException("local_runtime_mail_relay.failed", error);
      response.status(401).json({error: "Die Mail-Relay-Anfrage wurde abgelehnt."});
    }
  },
);

type RelayCommand =
  | {type: "pullEvents"; license: SignedRuntimeLicense; limit: number}
  | {type: "acknowledgeEvent"; license: SignedRuntimeLicense; eventId: string; receipt: string}
  | {type: "rejectEvent"; license: SignedRuntimeLicense; eventId: string; receipt: string; error: string}
  | {type: "listDeadLetters"; license: SignedRuntimeLicense}
  | {type: "replayDeadLetter"; license: SignedRuntimeLicense; eventId: string}
  | {type: "sendEmail"; license: SignedRuntimeLicense; connectorId: string; recipient: string; subject: string; body: string}
  | {type: "beginMicrosoftAuthorization"; license: SignedRuntimeLicense};

async function execute(command: RelayCommand): Promise<object> {
  switch (command.type) {
    case "pullEvents": return {events: await relay.pull(command.license, command.limit)};
    case "acknowledgeEvent": await relay.acknowledge(command); return {status: "ok"};
    case "rejectEvent": await relay.reject(command); return {status: "ok"};
    case "listDeadLetters": return {items: await relay.deadLetters(command.license)};
    case "replayDeadLetter": await relay.replay(command); return {status: "ok"};
    case "sendEmail": return sendEmail(command);
    case "beginMicrosoftAuthorization": return beginAuthorization(command.license);
  }
}

async function sendEmail(command: Extract<RelayCommand, {type: "sendEmail"}>) {
  const license = await verifier.verify(command.license);
  const repository = new FirestoreMailConnectorRepository(mailConnectorCipher());
  await assertLocalRuntimeConnector(repository, license, command.connectorId);
  const sent = await sendTeamMicrosoftGraphEmail({
    teamId: license.workspaceId, connectorId: command.connectorId,
    recipient: command.recipient, subject: command.subject, body: command.body,
    repository,
  });
  logInfo("local_runtime_mail_relay.email_sent", {licenseId: license.licenseId, connectorId: command.connectorId});
  return {sent};
}

async function assertLocalRuntimeConnector(
  repository: FirestoreMailConnectorRepository,
  license: {licenseId: string; workspaceId: string},
  connectorId: string,
): Promise<void> {
  const connection = await repository.loadConnector({teamId: license.workspaceId, connectorId});
  if (!connection || connection.connector.deliveryTarget !== "localRuntime" ||
    connection.connector.runtimeLicenseId !== license.licenseId) {
    throw new Error("Der Mail-Connector gehört nicht zu dieser lokalen Runtime.");
  }
}

async function beginAuthorization(license: SignedRuntimeLicense) {
  const active = await verifier.verify(license);
  const codeVerifier = authorizationCodeVerifier();
  return beginMailConnectorAuthorization({
    authorization: {
      id: authorizationId(), teamId: active.workspaceId, uid: `license-${active.licenseId}`,
      provider: "microsoftGraph", deliveryTarget: "localRuntime", runtimeLicenseId: active.licenseId,
      codeVerifier, expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    },
    codeChallenge: codeChallenge(codeVerifier),
    repository: new FirestoreMailConnectorRepository(mailConnectorCipher()),
    provider: microsoftGraphAuthorizationProvider(),
  });
}

function commandFrom(value: unknown): RelayCommand {
  const input = record(value);
  const license = licenseFrom(input.license);
  const type = text(input.type, "type", 40);
  if (type === "pullEvents") return {type, license, limit: count(input.limit)};
  if (type === "acknowledgeEvent") return {type, license, eventId: text(input.eventId, "eventId", 120), receipt: text(input.receipt, "receipt", 120)};
  if (type === "rejectEvent") return {type, license, eventId: text(input.eventId, "eventId", 120), receipt: text(input.receipt, "receipt", 120), error: text(input.error, "error", 500)};
  if (type === "listDeadLetters") return {type, license};
  if (type === "replayDeadLetter") return {type, license, eventId: text(input.eventId, "eventId", 120)};
  if (type === "sendEmail") return emailCommand(type, license, input);
  if (type === "beginMicrosoftAuthorization") return {type, license};
  throw new Error("Unbekannte Mail-Relay-Anfrage.");
}

function emailCommand(type: "sendEmail", license: SignedRuntimeLicense, input: Record<string, unknown>) {
  return {type, license, connectorId: text(input.connectorId, "connectorId", 120),
    recipient: text(input.recipient, "recipient", 320), subject: text(input.subject, "subject", 998),
    body: text(input.body, "body", 100_000)};
}

function licenseFrom(value: unknown): SignedRuntimeLicense {
  const signed = record(value);
  const payload = record(signed.payload);
  return {signature: text(signed.signature, "signature", 4096), payload: {
    licenseId: text(payload.licenseId, "licenseId", 200), licenseName: text(payload.licenseName, "licenseName", 200),
    activationId: text(payload.activationId, "activationId", 200), workspaceId: text(payload.workspaceId, "workspaceId", 200),
    issuedAt: text(payload.issuedAt, "issuedAt", 80), expiresAt: text(payload.expiresAt, "expiresAt", 80),
  }};
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new Error("Ungültige Mail-Relay-Anfrage.");
}

function text(value: unknown, name: string, max: number): string {
  if (typeof value !== "string" || value.trim().length === 0 || value.length > max) throw new Error(`${name} ist ungültig.`);
  return value.trim();
}

function count(value: unknown): number {
  return typeof value === "number" && Number.isInteger(value) && value > 0 && value <= 25 ? value : 10;
}
