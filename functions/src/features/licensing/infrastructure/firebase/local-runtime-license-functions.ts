import {onRequest} from "firebase-functions/v2/https";
import {runtimeActivationTokenFrom} from "../../domain/entities/activation-token.js";
import {type SignedRuntimeLicense} from "../../domain/entities/runtime-license-lease.js";
import {signRuntimeLicense} from "../license-lease-crypto.js";
import {FirestoreRuntimeLicenseRegistry} from "./firestore-runtime-license-registry.js";
import {localRuntimeLicenseSigningKey} from "./local-runtime-license-signing-key.js";
import {runtimeActivationVerdict} from "./runtime-activation-verification.js";

const licenseRegistry = new FirestoreRuntimeLicenseRegistry();

export const issueLocalRuntimeLicense = onRequest(
  {cors: false, invoker: "public", secrets: [localRuntimeLicenseSigningKey]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({error: "Methode nicht erlaubt."});
      return;
    }
    try {
      await respondToLicenseRequest(record(request.body), response);
    } catch {
      response.status(401).json({error: "Die Lizenzanfrage wurde abgelehnt."});
    }
  },
);

async function respondToLicenseRequest(
  body: Record<string, unknown>,
  response: {status(code: number): {json(body: unknown): void}},
): Promise<void> {
  if (body.action === "verify") {
    const verdict = await runtimeActivationVerdict(
      licenseRegistry, signedLicenseFrom(body.license), requiredString(body.activationSecret), new Date(),
    );
    response.status(200).json({status: verdict});
    return;
  }
  if (body.action === "release") {
    await licenseRegistry.release(
      signedLicenseFrom(body.license).payload,
      requiredString(body.activationSecret),
      new Date(),
    );
    response.status(200).json({status: "released"});
    return;
  }
  if (body.action !== "activate") throw new Error("Ungültige Lizenzanfrage.");
  const activation = await licenseRegistry.activate(
    runtimeActivationTokenFrom(body.activationToken), new Date(),
  );
  response.status(200).json({
    license: signRuntimeLicense(activation.license, localRuntimeLicenseSigningKey.value()),
    activationSecret: activation.activationSecret,
  });
}

function signedLicenseFrom(value: unknown): SignedRuntimeLicense {
  const signed = record(value);
  const payload = record(signed.payload);
  return {
    signature: requiredString(signed.signature),
    payload: {
      licenseId: requiredString(payload.licenseId),
      licenseName: requiredString(payload.licenseName),
      activationId: requiredString(payload.activationId),
      workspaceId: requiredString(payload.workspaceId),
      issuedAt: requiredString(payload.issuedAt),
      expiresAt: requiredString(payload.expiresAt),
    },
  };
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new Error("Ungültige Lizenzanfrage.");
}

function requiredString(value: unknown): string {
  if (typeof value === "string" && value.trim().length > 0 && value.length <= 4000) return value;
  throw new Error("Ungültige Lizenzanfrage.");
}
