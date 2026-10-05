import {type FastifyInstance, type FastifyPluginAsync, type FastifyReply} from "fastify";
import {type RuntimeLicenseService} from "../../../licensing/infrastructure/local/local-runtime-license-manager.js";
import {registerWorkspaceContext, type LocalRuntimeWorkspaceContext} from "../../../../shared/local/local-runtime-workspace-context.js";
import {type WebhookResult} from "../../domain/usecases/receive-webhook.js";

export type WebhookRoutesOptions = {
  licenses: Pick<RuntimeLicenseService, "activeContext" | "status">;
  workspaceContext: () => LocalRuntimeWorkspaceContext;
};

export const webhookBodyLimit = 1024 * 1024;

type HookParams = {triggerId: string; token: string};

/**
 * Eingang für externe Systeme. Anders als die API hat der Aufrufer keine Sitzung: Die Adresse mit ihrem Token
 * ersetzt die Anmeldung, deshalb liegt dieses Plugin neben `localRuntimeApi` und nicht darin.
 * Fehlerantworten sind bewusst einheitlich und kurz, damit sie nichts über vorhandene Auslöser verraten.
 */
export const webhookRoutes: FastifyPluginAsync<WebhookRoutesOptions> = async (app, {licenses, workspaceContext}) => {
  app.addHook("onRequest", async (_request, reply) => {
    if (licenses.activeContext() !== null) return;
    return reply.code(423).send({error: "Die Runtime benötigt eine gültige Lizenz."});
  });
  registerWorkspaceContext(app, workspaceContext);
  acceptRawBodies(app);
  app.setErrorHandler((error: Error & {code?: string}, request, reply) => {
    if (error.code === "FST_ERR_CTP_BODY_TOO_LARGE") return reply.code(413).send({error: "Die Anfrage ist zu groß."});
    if (error.code?.startsWith("FST_ERR_CTP_")) return reply.code(400).send({error: "Ungültige Anfrage."});
    request.workspace.logger.exception("webhook.failed", error, {triggerId: (request.params as Partial<HookParams>).triggerId});
    return reply.code(500).send({error: "Die Anfrage konnte nicht verarbeitet werden."});
  });

  app.route<{Params: HookParams}>({
    method: ["GET", "POST", "PUT"],
    url: "/hooks/:triggerId/:token",
    bodyLimit: webhookBodyLimit,
    handler: async (request, reply) => {
      const result = await request.workspace.webhooks.receive({
        triggerId: request.params.triggerId,
        token: request.params.token,
        method: request.method,
        query: stringQuery(request.query),
        headers: stringHeaders(request.headers),
        rawBody: Buffer.isBuffer(request.body) ? request.body : Buffer.alloc(0),
      });
      return respond(reply, result);
    },
  });
};

/** Die Signatur gilt den Rohbytes: Alle Inhaltstypen kommen unverändert als Buffer an, auch JSON. */
function acceptRawBodies(app: FastifyInstance): void {
  app.removeAllContentTypeParsers();
  app.addContentTypeParser("*", {parseAs: "buffer"}, (_request, body, done) => done(null, body));
}

function respond(reply: FastifyReply, result: WebhookResult): FastifyReply {
  switch (result.kind) {
    case "accepted": return reply.code(202).send();
    case "echo": return reply.code(200).header("content-type", "text/plain; charset=utf-8")
      .header("x-content-type-options", "nosniff").send(result.value);
    case "badRequest": return reply.code(400).send({error: "Ungültige Anfrage."});
    case "unauthorized": return reply.code(401).send({error: "Ungültige Signatur."});
    case "rateLimited": return reply.code(429).header("retry-after", String(result.retryAfterSeconds))
      .send({error: "Zu viele Anfragen."});
    case "notFound": return reply.code(404).send({error: "Nicht gefunden."});
  }
}

function stringQuery(query: unknown): Record<string, string> {
  const result: Record<string, string> = {};
  for (const [name, value] of Object.entries((query ?? {}) as Record<string, unknown>)) {
    const first: unknown = Array.isArray(value) ? value[0] : value;
    if (typeof first === "string") result[name] = first;
  }
  return result;
}

function stringHeaders(headers: Record<string, string | string[] | undefined>): Record<string, string> {
  const result: Record<string, string> = {};
  for (const [name, value] of Object.entries(headers)) {
    if (typeof value === "string") result[name] = value;
    else if (Array.isArray(value)) result[name] = value.join(", ");
  }
  return result;
}
