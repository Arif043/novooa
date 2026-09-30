import {type FastifyInstance} from "fastify";
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
    const authorization = request.headers.authorization;
    const token = authorization?.startsWith("Bearer ") ? authorization.slice(7).trim() : "";
    if (token.length > 0 && await sessions.verifySession(token)) return;
    return reply.code(401).send({error: "Anmeldung erforderlich."});
  });
}
