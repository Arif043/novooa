import {type RuntimeLicenseActivation} from "../../domain/entities/runtime-license-activation.js";
import {LicenseActivationRejectedError, LicenseGatewayUnavailableError} from "../../domain/entities/runtime-license-errors.js";
import {type SignedRuntimeLicense} from "../../domain/entities/runtime-license-lease.js";
import {type RuntimeLicenseVerdict} from "../../domain/entities/runtime-license-verification.js";

const verifyTimeoutMs = 15_000;

export interface RuntimeLicenseGatewayClient {
  activate(token: string): Promise<RuntimeLicenseActivation>;
  release(activation: RuntimeLicenseActivation): Promise<void>;
  /** Wirft [LicenseGatewayUnavailableError], wenn das Gateway kein eindeutiges Urteil liefert. */
  verify(activation: RuntimeLicenseActivation): Promise<RuntimeLicenseVerdict>;
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

  /**
   * Nur ein `200` mit `{status: "active" | "revoked"}` ist ein Urteil. Jede andere
   * Antwort — auch ein `4xx` eines älteren Gateways ohne `verify` — gilt als
   * nicht erreichbar, damit die Runtime nie wegen einer Störung gesperrt wird.
   */
  async verify(activation: RuntimeLicenseActivation): Promise<RuntimeLicenseVerdict> {
    const response = await this.send({
      action: "verify",
      license: activation.license,
      activationSecret: activation.activationSecret,
    }, AbortSignal.timeout(verifyTimeoutMs));
    if (!response.ok) throw new LicenseGatewayUnavailableError(`HTTP ${response.status}`);
    return verdictFrom(await response.json().catch(() => null));
  }

  private async request(body: object): Promise<Response> {
    const response = await this.send(body);
    if (response.ok) return response;
    if (response.status >= 400 && response.status < 500) throw new LicenseActivationRejectedError();
    throw new LicenseGatewayUnavailableError(`HTTP ${response.status}`);
  }

  private async send(body: object, signal?: AbortSignal): Promise<Response> {
    try {
      return await fetch(this.endpoint, {
        method: "POST",
        headers: {"content-type": "application/json"},
        body: JSON.stringify(body),
        signal,
      });
    } catch (error) {
      throw new LicenseGatewayUnavailableError(error instanceof Error ? error.message : String(error));
    }
  }
}

function verdictFrom(value: unknown): RuntimeLicenseVerdict {
  const status = (value as {status?: unknown} | null)?.status;
  if (status === "active" || status === "revoked") return status;
  throw new LicenseGatewayUnavailableError("Unbekannte Antwort auf die Lizenzprüfung.");
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
