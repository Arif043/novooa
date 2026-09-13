import {type SignedLocalRuntimeLicense} from
  "../../../licensing/domain/entities/local-runtime-license-lease.js";
import {
  type LocalRuntimePushRelayClient,
} from "./local-runtime-push-relay-client.js";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";

export class LocalPushDeviceHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly signedLicense: () => SignedLocalRuntimeLicense | null,
    private readonly relay: LocalRuntimePushRelayClient,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (request.method !== "POST") return null;
    if (request.url === "/v1/push-devices") return this.register(request.body);
    if (request.url === "/v1/push-devices/remove") return this.remove(request.body);
    return null;
  }

  private async register(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      await this.relay.register(this.requiredLicense(), deviceFrom(body));
      return {body: {status: "registered"}, statusCode: 200};
    } catch (error) {
      return errorResponse(error);
    }
  }

  private async remove(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      await this.relay.remove(this.requiredLicense(), tokenFrom(body));
      return {body: {status: "removed"}, statusCode: 200};
    } catch (error) {
      return errorResponse(error);
    }
  }

  private requiredLicense(): SignedLocalRuntimeLicense {
    const license = this.signedLicense();
    if (license === null) throw new LocalPushDeviceRequestError("Die lokale Runtime benötigt eine gültige Lizenz.");
    return license;
  }
}

function deviceFrom(value: unknown): {token: string; platform: string} {
  const input = record(value);
  return {token: text(input.token, "token", 4096, 16), platform: text(input.platform, "platform", 40)};
}

function tokenFrom(value: unknown): string {
  return text(record(value).token, "token", 4096, 16);
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new LocalPushDeviceRequestError("Die Push-Geräteanfrage ist ungültig.");
}

function text(value: unknown, name: string, max: number, min = 1): string {
  if (typeof value !== "string" || value.trim().length < min || value.length > max) {
    throw new LocalPushDeviceRequestError(`${name} ist ungültig.`);
  }
  return value.trim();
}

function errorResponse(error: unknown): LocalRuntimeResponse {
  const message = error instanceof Error ? error.message : "Das Push-Gerät konnte nicht registriert werden.";
  const statusCode = error instanceof LocalPushDeviceRequestError ? 400 : 503;
  return {body: {error: message}, statusCode};
}

class LocalPushDeviceRequestError extends Error {}
