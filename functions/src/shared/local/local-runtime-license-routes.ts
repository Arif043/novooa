import {type FastifyInstance, type FastifyReply} from "fastify";
import {
  InvalidActivationTokenError,
  LicenseActivationRejectedError,
  LicenseGatewayUnavailableError,
} from "../../features/licensing/domain/entities/runtime-license-errors.js";
import {type ActivateRuntime} from "../../features/licensing/domain/usecases/activate-runtime.js";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";

type ActivationFailure = {status: number; code: string; error: string};

export function registerRuntimeLicenseRoutes(
  http: FastifyInstance, licenses: RuntimeLicenseService, activateRuntime: ActivateRuntime,
): void {
  http.get("/v1/license", async () => licenses.status());
  registerActivationRoute(http, activateRuntime);
  http.post("/v1/license/release", async (_request, reply) => {
    try { await licenses.release(); return {status: "notActivated"}; }
    catch (error) {
      reportLicenseEvent("local_runtime.license_release_failed", error);
      return reply.code(409).send({error: "Die Lizenz konnte nicht freigegeben werden."});
    }
  });
}

function registerActivationRoute(http: FastifyInstance, activateRuntime: ActivateRuntime): void {
  http.post<{Body: {activationToken: string}}>("/v1/license/activate", {
    schema: {body: {type: "object", required: ["activationToken"], properties: {
      activationToken: {type: "string", minLength: 1, maxLength: 400, pattern: "\\S"},
    }}},
  }, async (request, reply) => {
    try {
      const context = await activateRuntime.execute(request.body.activationToken);
      return {status: "active", expiresAt: context.expiresAt, name: context.licenseName};
    } catch (error) {
      return rejectActivation(error, reply);
    }
  });
}

function rejectActivation(error: unknown, reply: FastifyReply): FastifyReply {
  const failure = activationFailureFor(error);
  reportLicenseEvent("local_runtime.license_activation_failed", error, failure.code);
  return reply.code(failure.status).send({error: failure.error, code: failure.code});
}

function activationFailureFor(error: unknown): ActivationFailure {
  if (error instanceof InvalidActivationTokenError) {
    return {status: 400, code: "invalid_token",
      error: "Der Lizenz-Token hat ein ungültiges Format. Er besteht aus 16 Zeichen (A–Z ohne I und O, 2–9)."};
  }
  if (error instanceof LicenseActivationRejectedError) {
    return {status: 401, code: "license_rejected",
      error: "Der Lizenz-Token ist unbekannt, abgelaufen oder wurde bereits verwendet."};
  }
  if (error instanceof LicenseGatewayUnavailableError) {
    return {status: 502, code: "gateway_unavailable",
      error: "Das Lizenz-Gateway ist nicht erreichbar. Bitte prüfe die Internetverbindung der Runtime."};
  }
  return {status: 500, code: "activation_failed", error: "Die Runtime konnte nicht aktiviert werden."};
}

/** Vor der Aktivierung gibt es noch keinen team-gebundenen Logger — daher direkt nach Stdout. */
function reportLicenseEvent(event: string, error: unknown, code?: string): void {
  const message = error instanceof Error ? error.message : String(error);
  const detail = error instanceof LicenseGatewayUnavailableError ? error.causeDetail : undefined;
  console.error(JSON.stringify({event, code, message, detail}));
}
