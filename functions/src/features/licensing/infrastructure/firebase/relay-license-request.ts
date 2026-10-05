import {type SignedRuntimeLicense} from "../../domain/entities/runtime-license-lease.js";

/** Liest die signierte Lizenz aus dem Body einer Relay-Anfrage; wirft bei ungültiger Form. */
export function signedLicenseFromRequest(value: unknown): SignedRuntimeLicense {
  const signed = record(value);
  const payload = record(signed.payload);
  return {
    signature: text(signed.signature, "signature", 4096),
    payload: {
      licenseId: text(payload.licenseId, "licenseId", 200),
      licenseName: text(payload.licenseName, "licenseName", 200),
      activationId: text(payload.activationId, "activationId", 200),
      workspaceId: text(payload.workspaceId, "workspaceId", 200),
      issuedAt: text(payload.issuedAt, "issuedAt", 80),
      expiresAt: text(payload.expiresAt, "expiresAt", 80),
    },
  };
}

export function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new Error("Ungültige Relay-Anfrage.");
}

function text(value: unknown, name: string, max: number): string {
  if (typeof value !== "string" || value.trim().length === 0 || value.length > max) throw new Error(`${name} ist ungültig.`);
  return value.trim();
}
