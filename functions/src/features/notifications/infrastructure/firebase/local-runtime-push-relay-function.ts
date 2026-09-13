import {onRequest} from "firebase-functions/v2/https";
import {type SignedLocalRuntimeLicense} from
  "../../../licensing/domain/entities/local-runtime-license-lease.js";
import {FirebaseLocalRuntimeRelayLicenseVerifier} from
  "../../../licensing/infrastructure/firebase/firebase-local-runtime-relay-license-verifier.js";
import {localRuntimeLicenseSigningKey} from
  "../../../licensing/infrastructure/firebase/local-runtime-license-signing-key.js";
import {LocalRuntimePushRelay} from "../../domain/usecases/local-runtime-push-relay.js";
import {logException, logInfo} from "../../../../shared/logging/logger.js";
import {FirebasePushNotificationSender} from "./firebase-push-notification-sender.js";
import {
  FirestoreLocalRuntimeFcmTokenStore,
  FirestoreLocalRuntimePushDeviceStore,
} from "./firestore-local-runtime-push-device-store.js";

const relay = new LocalRuntimePushRelay(
  new FirebaseLocalRuntimeRelayLicenseVerifier(),
  new FirestoreLocalRuntimePushDeviceStore(),
  new FirebasePushNotificationSender(new FirestoreLocalRuntimeFcmTokenStore()),
);

export const localRuntimePushRelay = onRequest(
  {cors: false, invoker: "public", secrets: [localRuntimeLicenseSigningKey]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({error: "Methode nicht erlaubt."});
      return;
    }
    try {
      await execute(commandFrom(request.body));
      response.status(200).json({status: "ok"});
    } catch (error) {
      logException("local_runtime_push_relay.failed", error);
      response.status(401).json({error: "Die Relay-Anfrage wurde abgelehnt."});
    }
  },
);

type RelayCommand =
  | {type: "registerDevice"; license: SignedLocalRuntimeLicense; token: string; platform: string}
  | {type: "removeDevice"; license: SignedLocalRuntimeLicense; token: string}
  | {
    type: "send";
    license: SignedLocalRuntimeLicense;
    title: string;
    body: string;
    data: Record<string, string>;
  };

async function execute(command: RelayCommand): Promise<void> {
  switch (command.type) {
    case "registerDevice":
      await relay.register(command.license, {token: command.token, platform: command.platform});
      logInfo("local_runtime_push_device.registered", {platform: command.platform});
      return;
    case "removeDevice":
      await relay.unregister(command.license, command.token);
      return;
    case "send":
      await relay.send(command.license, {
        title: command.title,
        body: command.body,
        data: command.data,
      });
  }
}

function commandFrom(value: unknown): RelayCommand {
  const input = record(value);
  const license = licenseFrom(input.license);
  const type = text(input.type, "type", 40);
  if (type === "registerDevice") {
    return {type, license, token: text(input.token, "token", 4096, 16), platform: text(input.platform, "platform", 40)};
  }
  if (type === "removeDevice") {
    return {type, license, token: text(input.token, "token", 4096, 16)};
  }
  if (type === "send") {
    return {
      type,
      license,
      title: text(input.title, "title", 160),
      body: text(input.body, "body", 500),
      data: stringRecord(input.data, "data"),
    };
  }
  throw new Error("Unbekannte Relay-Anfrage.");
}

function stringRecord(value: unknown, name: string): Record<string, string> {
  const fields = record(value);
  if (Object.keys(fields).length > 20) throw new Error(`${name} ist ungültig.`);
  return Object.fromEntries(Object.entries(fields).map(([key, entry]) => [
    text(key, `${name}.key`, 80),
    text(entry, `${name}.${key}`, 500),
  ]));
}

function licenseFrom(value: unknown): SignedLocalRuntimeLicense {
  const signed = record(value);
  const payload = record(signed.payload);
  return {
    signature: text(signed.signature, "signature", 4096),
    payload: {
      licenseId: text(payload.licenseId, "licenseId", 200),
      workspaceId: text(payload.workspaceId, "workspaceId", 200),
      issuedAt: text(payload.issuedAt, "issuedAt", 80),
      ...(payload.expiresAt === null || payload.expiresAt === undefined
        ? {} : {expiresAt: text(payload.expiresAt, "expiresAt", 80)}),
    },
  };
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new Error("Ungültige Relay-Anfrage.");
}

function text(value: unknown, name: string, max: number, min = 1): string {
  if (typeof value !== "string" || value.trim().length < min || value.length > max) {
    throw new Error(`${name} ist ungültig.`);
  }
  return value.trim();
}
