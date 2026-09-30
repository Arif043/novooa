import {type FastifyInstance} from "fastify";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {type ActivateRuntime} from "../../features/licensing/domain/usecases/activate-runtime.js";

export function registerRuntimeLicenseRoutes(
  http: FastifyInstance, licenses: RuntimeLicenseService, activateRuntime: ActivateRuntime,
): void {
  http.get("/v1/license", async () => licenses.status());
  registerActivationRoute(http, activateRuntime);
  http.post("/v1/license/release", async (_request, reply) => {
    try { await licenses.release(); return {status: "notActivated"}; }
    catch { return reply.code(409).send({error: "Die Lizenz konnte nicht freigegeben werden."}); }
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
    } catch { return reply.code(401).send({error: "Die Runtime konnte nicht aktiviert werden."}); }
  });
}
