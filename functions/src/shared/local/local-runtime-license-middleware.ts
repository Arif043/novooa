import {type RuntimeLicenseActivationInput, type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {type LocalRuntimeRequest, type LocalRuntimeRequestHandler, type LocalRuntimeResponse} from "./local-runtime-http-server.js";

export class RuntimeLicenseMiddleware implements LocalRuntimeRequestHandler {
  constructor(
    private readonly licenseService: RuntimeLicenseService,
    private readonly application: LocalRuntimeRequestHandler & {
      activate(context: Awaited<ReturnType<RuntimeLicenseService["activate"]>>): Promise<void>;
    },
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (isStatusRequest(request)) return {body: this.licenseService.status(), statusCode: 200};
    if (isActivationRequest(request)) return this.activate(request.body);
    if (isReleaseRequest(request)) return this.release();
    if (this.licenseService.activeContext() === null) return blockedResponse(this.licenseService.status());
    return this.application.handle(request);
  }

  private async activate(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const context = await this.licenseService.activate(activationFrom(body));
      await this.application.activate(context);
      return {body: {status: "active", expiresAt: context.expiresAt, name: context.licenseName}, statusCode: 200};
    } catch { return {body: {error: "Die Runtime konnte nicht aktiviert werden."}, statusCode: 401}; }
  }

  private async release(): Promise<LocalRuntimeResponse> {
    try { await this.licenseService.release(); return {body: {status: "notActivated"}, statusCode: 200}; }
    catch { return {body: {error: "Die Lizenz konnte nicht freigegeben werden."}, statusCode: 409}; }
  }
}

function isStatusRequest(request: LocalRuntimeRequest): boolean { return request.method === "GET" && request.url === "/v1/license"; }
function isActivationRequest(request: LocalRuntimeRequest): boolean { return request.method === "POST" && request.url === "/v1/license/activate"; }
function isReleaseRequest(request: LocalRuntimeRequest): boolean { return request.method === "POST" && request.url === "/v1/license/release"; }
function activationFrom(value: unknown): RuntimeLicenseActivationInput {
  if (value === null || typeof value !== "object" || Array.isArray(value)) throw new Error("Ungültige Aktivierung.");
  const token = (value as Record<string, unknown>).activationToken;
  if (typeof token !== "string" || token.trim().length === 0 || token.length > 400) throw new Error("Ungültige Aktivierung.");
  return {activationToken: token};
}
function blockedResponse(status: {state: string; expiresAt?: string}): LocalRuntimeResponse {
  return {statusCode: 423, body: {error: "Die Runtime benötigt eine gültige Lizenz.", licenseStatus: status.state, expiresAt: status.expiresAt}};
}
