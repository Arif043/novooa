import {type FastifyInstance, type FastifyReply, type FastifyRequest} from "fastify";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {type RuntimeActor} from "../../features/runtime_users/domain/entities/runtime-user.js";
import {mayAccess} from "./local-runtime-role-policy.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

declare module "fastify" {
  interface FastifyRequest {
    /** Wer anfragt; gesetzt vom Session-Hook, auf öffentlichen Routen nicht vorhanden. */
    actor: RuntimeActor;
  }
}

/** Ohne Sitzung erreichbar: Einrichtung, Anmeldung, Einladung einlösen, Notzugang. */
const publicRoutes = ["/v1/auth/login", "/v1/setup", "/v1/auth/invitations/redeem", "/v1/auth/recover"];

/** Nur im API-Plugin registrieren; Lizenz-Endpunkte und Web-Build bleiben außerhalb. */
export function registerLocalRuntimeAccessHooks(
  http: FastifyInstance, licenses: Pick<RuntimeLicenseService, "activeContext" | "status">,
  sessions: Pick<LocalRuntimeSessionStore, "verifySession">,
): void {
  http.decorateRequest("actor", null as unknown as RuntimeActor);
  http.addHook("onRequest", async (_request, reply) => {
    if (licenses.activeContext() !== null) return;
    const status = licenses.status();
    return reply.code(423).send({
      error: "Die Runtime benötigt eine gültige Lizenz.", licenseStatus: status.state, expiresAt: status.expiresAt,
    });
  });
  http.addHook("onRequest", async (request, reply) => {
    const url = request.routeOptions.url ?? "";
    if (publicRoutes.includes(url)) return;
    const actor = await sessionActor(request, sessions);
    if (actor === null) return sendSessionRequired(reply);
    if (!mayAccess(actor, request.method, url)) return sendAdminRequired(reply);
    request.actor = actor;
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

export function sendAdminRequired(reply: FastifyReply): FastifyReply {
  return reply.code(403).send({error: "Das dürfen nur Admins.", code: "admin_required"});
}

/** Wer mit `Authorization: Bearer <token>` anfragt; ohne gültige Sitzung `null`. */
export async function sessionActor(
  request: FastifyRequest, sessions: Pick<LocalRuntimeSessionStore, "verifySession">,
): Promise<RuntimeActor | null> {
  const token = bearerTokenOf(request);
  return token === null ? null : sessions.verifySession(token);
}

/** Das Session-Token aus `Authorization: Bearer <token>`, sonst `null`. */
export function bearerTokenOf(request: FastifyRequest): string | null {
  const authorization = request.headers.authorization;
  const token = authorization?.startsWith("Bearer ") ? authorization.slice(7).trim() : "";
  return token.length > 0 ? token : null;
}
