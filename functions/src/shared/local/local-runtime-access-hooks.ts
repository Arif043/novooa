import {type FastifyInstance, type FastifyReply, type FastifyRequest} from "fastify";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

/** Nur im API-Plugin registrieren; Lizenz-Endpunkte und Web-Build bleiben außerhalb. */
export function registerLocalRuntimeAccessHooks(
  http: FastifyInstance, licenses: Pick<RuntimeLicenseService, "activeContext" | "status">,
  sessions: Pick<LocalRuntimeSessionStore, "verifySession">,
): void {
  http.addHook("onRequest", async (_request, reply) => {
    if (licenses.activeContext() !== null) return;
    const status = licenses.status();
    return reply.code(423).send({
      error: "Die Runtime benötigt eine gültige Lizenz.", licenseStatus: status.state, expiresAt: status.expiresAt,
    });
  });
  http.addHook("onRequest", async (request, reply) => {
    if (["/v1/auth/login", "/v1/setup"].includes(request.routeOptions.url ?? "")) return;
    if (await hasValidSession(request, sessions)) return;
    return sendSessionRequired(reply);
  });
}

/**
 * Einheitliche Antwort, wenn eine Sitzung fehlt, abgelaufen oder beendet ist. Der Code `session_required`
 * unterscheidet sie von anderen `401` (falsches Passwort, abgelehnter Lizenz-Token); die App kehrt nur
 * darauf hin zur Anmeldung zurück.
 */
export function sendSessionRequired(reply: FastifyReply): FastifyReply {
  return reply.code(401).send({error: "Anmeldung erforderlich.", code: "session_required"});
}

/** Trägt die Anfrage ein gültiges `Authorization: Bearer <token>`? */
export async function hasValidSession(
  request: FastifyRequest, sessions: Pick<LocalRuntimeSessionStore, "verifySession">,
): Promise<boolean> {
  const token = bearerTokenOf(request);
  return token !== null && await sessions.verifySession(token);
}

/** Das Session-Token aus `Authorization: Bearer <token>`, sonst `null`. */
export function bearerTokenOf(request: FastifyRequest): string | null {
  const authorization = request.headers.authorization;
  const token = authorization?.startsWith("Bearer ") ? authorization.slice(7).trim() : "";
  return token.length > 0 ? token : null;
}
