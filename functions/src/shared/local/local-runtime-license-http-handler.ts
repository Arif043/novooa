import {
  type LocalRuntimeLicenseActivation,
  type LocalRuntimeLicenseService,
} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "./local-runtime-http-server.js";

export class LocalRuntimeLicenseHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly licenseService: LocalRuntimeLicenseService,
    private readonly application: LocalRuntimeRequestHandler & {
      activate(context: Awaited<ReturnType<LocalRuntimeLicenseService["activate"]>>): Promise<void>;
    },
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (isStatusRequest(request)) return {body: this.licenseService.status(), statusCode: 200};
    if (isActivationRequest(request)) return this.activate(request.body);
    if (this.licenseService.activeContext() === null) return blockedResponse(this.licenseService.status());
    return this.application.handle(request);
  }

  private async activate(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const context = await this.licenseService.activate(activationFrom(body));
      await this.application.activate(context);
      return {body: {status: "active", expiresAt: context.expiresAt}, statusCode: 200};
    } catch {
      return {
        body: {error: "Die lokale Runtime konnte nicht aktiviert werden."},
        statusCode: 401,
      };
    }
  }
}

function isStatusRequest(request: LocalRuntimeRequest): boolean {
  return request.method === "GET" && request.url === "/v1/license";
}

function isActivationRequest(request: LocalRuntimeRequest): boolean {
  return request.method === "POST" && request.url === "/v1/license/activate";
}

function activationFrom(value: unknown): LocalRuntimeLicenseActivation {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Ungültige Aktivierung.");
  }
  const input = value as Record<string, unknown>;
  return {
    activationToken: requiredString(input.activationToken),
  };
}

function requiredString(value: unknown): string {
  if (typeof value === "string" && value.trim().length > 0 && value.length <= 400) return value;
  throw new Error("Ungültige Aktivierung.");
}

function blockedResponse(status: {state: string; expiresAt?: string}): LocalRuntimeResponse {
  return {
    statusCode: 423,
    body: {
      error: "Die lokale Runtime benötigt eine gültige Lizenz.",
      licenseStatus: status.state,
      expiresAt: status.expiresAt,
    },
  };
}
