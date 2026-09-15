import {type RuntimeLicenseActivation} from "../../domain/entities/runtime-license-activation.js";
import {type SignedRuntimeLicense} from "../../domain/entities/runtime-license-lease.js";

export interface RuntimeLicenseGatewayClient {
  activate(token: string): Promise<RuntimeLicenseActivation>;
  release(activation: RuntimeLicenseActivation): Promise<void>;
}

export class HttpRuntimeLicenseGatewayClient implements RuntimeLicenseGatewayClient {
  private readonly endpoint: URL;

  constructor(endpoint: string) {
    this.endpoint = new URL(endpoint);
    if (this.endpoint.protocol !== "https:") throw new Error("Der Lizenz-Gateway muss HTTPS verwenden.");
  }

  async activate(token: string): Promise<RuntimeLicenseActivation> {
    const response = await this.request({action: "activate", activationToken: token});
    return activationFrom(await response.json());
  }

  async release(activation: RuntimeLicenseActivation): Promise<void> {
    await this.request({
      action: "release",
      license: activation.license,
      activationSecret: activation.activationSecret,
    });
  }

  private async request(body: object): Promise<Response> {
    const response = await fetch(this.endpoint, {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify(body),
    });
    if (!response.ok) throw new Error("Die Lizenzanfrage wurde abgelehnt.");
    return response;
  }
}

function activationFrom(value: unknown): RuntimeLicenseActivation {
  const input = record(value);
  return {
    license: signedLicenseFrom(input.license),
    activationSecret: requiredString(input.activationSecret),
  };
}

function signedLicenseFrom(value: unknown): SignedRuntimeLicense {
  const signed = record(value);
  const payload = record(signed.payload);
  return {
    payload: {
      licenseId: requiredString(payload.licenseId),
      licenseName: requiredString(payload.licenseName),
      activationId: requiredString(payload.activationId),
      workspaceId: requiredString(payload.workspaceId),
      issuedAt: requiredString(payload.issuedAt),
      expiresAt: requiredString(payload.expiresAt),
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
