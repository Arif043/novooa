import {type SignedLocalRuntimeLicense} from "../../domain/entities/local-runtime-license-lease.js";

export interface LocalRuntimeLicenseGatewayClient {
  requestLicense(token: string): Promise<SignedLocalRuntimeLicense>;
}

export class HttpLocalRuntimeLicenseGatewayClient
implements LocalRuntimeLicenseGatewayClient {
  private readonly endpoint: URL;

  constructor(endpoint: string) {
    this.endpoint = new URL(endpoint);
    if (this.endpoint.protocol !== "https:") throw new Error("Der Lizenz-Gateway muss HTTPS verwenden.");
  }

  async requestLicense(token: string): Promise<SignedLocalRuntimeLicense> {
    const response = await fetch(this.endpoint, {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({activationToken: token}),
    });
    if (!response.ok) throw new Error("Der Lizenzschlüssel wurde abgelehnt.");
    return signedLicenseFrom(await response.json());
  }
}

function signedLicenseFrom(value: unknown): SignedLocalRuntimeLicense {
  const signed = record(value);
  const payload = record(signed.payload);
  return {
    payload: {
      licenseId: requiredString(payload.licenseId),
      workspaceId: requiredString(payload.workspaceId),
      issuedAt: requiredString(payload.issuedAt),
      expiresAt: optionalString(payload.expiresAt),
    },
    signature: requiredString(signed.signature),
  };
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new Error("Die Lizenzantwort ist ungültig.");
}

function requiredString(value: unknown): string {
  if (typeof value === "string" && value.trim().length > 0 && value.length <= 4000) return value;
  throw new Error("Die Lizenzantwort ist ungültig.");
}

function optionalString(value: unknown): string | undefined {
  if (value === undefined || value === null) return undefined;
  return requiredString(value);
}
