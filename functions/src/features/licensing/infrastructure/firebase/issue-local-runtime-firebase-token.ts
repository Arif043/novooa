import {createHash} from "node:crypto";
import {getAuth} from "firebase-admin/auth";
import {onRequest} from "firebase-functions/v2/https";
import {type SignedRuntimeLicense} from "../../domain/entities/runtime-license-lease.js";
import {FirebaseRuntimeRelayLicenseVerifier} from "./firebase-runtime-relay-license-verifier.js";
import {FirestoreRuntimeLicenseRegistry} from "./firestore-runtime-license-registry.js";
import {localRuntimeLicenseSigningKey} from "./local-runtime-license-signing-key.js";
import {logException} from "../../../../shared/logging/logger.js";

const licenses = new FirebaseRuntimeRelayLicenseVerifier();
const registry = new FirestoreRuntimeLicenseRegistry();

export const issueLocalRuntimeFirebaseToken = onRequest(
  {cors: false, invoker: "public", secrets: [localRuntimeLicenseSigningKey]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({error: "Methode nicht erlaubt."});
      return;
    }
    try {
      response.status(200).json({token: await tokenFor(request.body)});
    } catch (error) {
      logException("local_runtime.firebase_token_rejected", error);
      response.status(401).json({error: "Die Firebase-Anmeldung wurde abgelehnt."});
    }
  },
);

async function tokenFor(value: unknown): Promise<string> {
  const input = record(value);
  const license = licenseFrom(input.license);
  const activationSecret = text(input.activationSecret, "activationSecret", 4096, 32);
  const active = await licenses.verify(license);
  await registry.verifyActiveActivation(license, activationSecret, new Date());
  return getAuth().createCustomToken(
    runtimeUid(active.licenseId, active.activationId),
    {
      localRuntime: true,
      runtimeLicenseId: active.licenseId,
      runtimeActivationId: active.activationId,
      runtimeScopes: ["communication", "pushNotifications"],
    },
  );
}

function runtimeUid(licenseId: string, activationId: string): string {
  return `runtime-${createHash("sha256").update(`${licenseId}:${activationId}`).digest("base64url")}`;
}

function licenseFrom(value: unknown): SignedRuntimeLicense {
  const signed = record(value); const payload = record(signed.payload);
  return {signature: text(signed.signature, "signature", 4096), payload: {
    licenseId: text(payload.licenseId, "licenseId", 200),
    licenseName: text(payload.licenseName, "licenseName", 200),
    activationId: text(payload.activationId, "activationId", 200),
    workspaceId: text(payload.workspaceId, "workspaceId", 200),
    issuedAt: text(payload.issuedAt, "issuedAt", 80),
    expiresAt: text(payload.expiresAt, "expiresAt", 80),
  }};
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new Error("Die Firebase-Anfrage ist ungültig.");
}

function text(value: unknown, name: string, maximum: number, minimum = 1): string {
  if (typeof value !== "string" || value.trim().length < minimum || value.length > maximum) {
    throw new Error(`${name} ist ungültig.`);
  }
  return value.trim();
}
