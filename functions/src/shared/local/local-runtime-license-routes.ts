import {type FastifyInstance, type FastifyReply, type FastifyRequest} from "fastify";
import {type LocalRuntimeAccessCredentialStore} from "./local-runtime-access-credential-store.js";
import {hasValidSession, sendSessionRequired} from "./local-runtime-access-hooks.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";
import {
  InvalidActivationTokenError,
  LicenseActivationRejectedError,
  LicenseGatewayUnavailableError,
  RuntimeAlreadyActivatedError,
} from "../../features/licensing/domain/entities/runtime-license-errors.js";
import {type ActivateRuntime} from "../../features/licensing/domain/usecases/activate-runtime.js";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";

type ActivationFailure = {status: number; code: string; error: string};

/** Wer die Lizenz freigeben darf: angemeldete Betreiber, vor der Ersteinrichtung jeder. */
export type ReleaseAuthorization = {
  credentials: Pick<LocalRuntimeAccessCredentialStore, "hasCredential">;
  sessions: Pick<LocalRuntimeSessionStore, "verifySession">;
};

export function registerRuntimeLicenseRoutes(
  http: FastifyInstance, licenses: RuntimeLicenseService, activateRuntime: ActivateRuntime,
  releaseAuthorization: ReleaseAuthorization,
): void {
  http.get("/v1/license", async () => licenses.status());
  registerActivationRoute(http, activateRuntime);
  http.post("/v1/license/release", {
    preHandler: async (request, reply) => {
      if (await mayRelease(request, releaseAuthorization)) return;
      return sendSessionRequired(reply);
    },
  }, async (_request, reply) => {
    try { await licenses.release(); return {status: "notActivated"}; }
    catch (error) {
      reportLicenseEvent("local_runtime.license_release_failed", error);
      return reply.code(409).send({error: "Die Lizenz konnte nicht freigegeben werden."});
    }
  });
}

/**
 * Das Freigeben sperrt die Runtime und gibt die Lizenz beim Gateway frei — das
 * darf nur ein angemeldeter Betreiber. Solange noch kein Passwort gesetzt ist,
 * kann sich niemand anmelden; dann bleibt die Freigabe offen, weil Lizenzen
 * ohne gespeicherten Token-Nachweis nur über Freigeben und erneutes Aktivieren
 * eingerichtet werden können (siehe docs/notes/runtime-ersteinrichtung.md).
 */
async function mayRelease(request: FastifyRequest, {credentials, sessions}: ReleaseAuthorization): Promise<boolean> {
  if (!await credentials.hasCredential()) return true;
  return hasValidSession(request, sessions);
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

const activationFailures: ReadonlyArray<[new (...args: never[]) => Error, ActivationFailure]> = [
  [InvalidActivationTokenError, {status: 400, code: "invalid_token",
    error: "Der Lizenz-Token hat ein ungültiges Format. Er besteht aus 16 Zeichen (A–Z ohne I und O, 2–9)."}],
  [LicenseActivationRejectedError, {status: 401, code: "license_rejected",
    error: "Der Lizenz-Token ist unbekannt, abgelaufen oder wurde bereits verwendet."}],
  [LicenseGatewayUnavailableError, {status: 502, code: "gateway_unavailable",
    error: "Das Lizenz-Gateway ist nicht erreichbar. Bitte prüfe die Internetverbindung der Runtime."}],
  [RuntimeAlreadyActivatedError, {status: 409, code: "already_activated",
    error: "Diese Runtime ist bereits mit einer anderen Lizenz aktiviert."}],
];

function activationFailureFor(error: unknown): ActivationFailure {
  const match = activationFailures.find(([errorType]) => error instanceof errorType);
  return match?.[1] ?? {status: 500, code: "activation_failed", error: "Die Runtime konnte nicht aktiviert werden."};
}

/** Vor der Aktivierung gibt es noch keinen team-gebundenen Logger — daher direkt nach Stdout. */
function reportLicenseEvent(event: string, error: unknown, code?: string): void {
  const message = error instanceof Error ? error.message : String(error);
  const detail = error instanceof LicenseGatewayUnavailableError ? error.causeDetail : undefined;
  console.error(JSON.stringify({event, code, message, detail}));
}
