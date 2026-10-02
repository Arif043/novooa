import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply} from "fastify";
import {ErrorResponse} from "../../../../shared/local/local-runtime-http-schemas.js";
import {SkillCatalogError} from "../../domain/entities/skill-catalog.js";
import {type SkillCatalog} from "../../domain/repositories/skill-catalog.js";

export type SkillCatalogRoutesOptions = {
  /** `undefined`, wenn kein Zugang zu skills.sh eingerichtet ist (`SKILLS_SH_BASE_URL` / `SKILLS_SH_TOKEN`). */
  catalog?: SkillCatalog;
};

const CatalogSkill = Type.Object({
  id: Type.String(), slug: Type.String(), name: Type.String(), source: Type.String(), installs: Type.Integer(),
  sourceType: Type.String(), url: Type.String(), isDuplicate: Type.Boolean(),
});
const Audit = Type.Object({
  provider: Type.String(), status: Type.Union([Type.Literal("pass"), Type.Literal("warn"), Type.Literal("fail")]),
  summary: Type.String(), riskLevel: Type.Optional(Type.String()), auditedAt: Type.Optional(Type.String()),
});
const failures = {400: ErrorResponse, 404: ErrorResponse, 429: ErrorResponse, 503: ErrorResponse};
const notConfigured = "Der Skill-Katalog ist nicht eingerichtet. Du kannst Skills trotzdem über GitHub, ZIP oder einen Ordner importieren.";

/** Suche und Bestenliste von skills.sh. Alle Aufrufe laufen über den Client mit Rate-Limit-Beachtung. */
export const skillCatalogRoutes: FastifyPluginAsyncTypebox<SkillCatalogRoutesOptions> = async (app, {catalog}) => {
  app.get("/v1/skills/catalog/status", {schema: {response: {200: Type.Object({available: Type.Boolean()})}}},
    async () => ({available: catalog !== undefined}));

  app.get("/v1/skills/catalog/search", {
    schema: {
      querystring: Type.Object({q: Type.String({maxLength: 200}), limit: Type.Optional(Type.Integer({minimum: 1, maximum: 200}))}),
      response: {...failures, 200: Type.Object({items: Type.Array(CatalogSkill)})},
    },
  }, async (request, reply) => guarded(reply, catalog, async (available) =>
    ({items: await available.search(request.query.q, request.query.limit)})));

  app.get("/v1/skills/catalog/browse", {
    schema: {
      querystring: Type.Object({
        view: Type.Optional(Type.Union([Type.Literal("all-time"), Type.Literal("trending"), Type.Literal("hot")])),
        page: Type.Optional(Type.Integer({minimum: 0, maximum: 10_000})),
      }),
      response: {...failures, 200: Type.Object({items: Type.Array(CatalogSkill), hasMore: Type.Boolean()})},
    },
  }, async (request, reply) => guarded(reply, catalog, (available) =>
    available.browse(request.query.view ?? "all-time", request.query.page ?? 0)));

  app.get("/v1/skills/catalog/audits", {
    schema: {querystring: Type.Object({id: Type.String({minLength: 3, maxLength: 300})}), response: {...failures, 200: Type.Object({items: Type.Array(Audit)})}},
  }, async (request, reply) => guarded(reply, catalog, async (available) =>
    ({items: await available.audits(request.query.id)})));
};

async function guarded<Result>(
  reply: FastifyReply, catalog: SkillCatalog | undefined, run: (catalog: SkillCatalog) => Promise<Result>,
): Promise<Result | FastifyReply> {
  if (catalog === undefined) return reply.code(503).send({error: notConfigured});
  try {
    return await run(catalog);
  } catch (error) {
    if (!(error instanceof SkillCatalogError)) throw error;
    if (error.retryAfterSeconds !== undefined) reply.header("retry-after", String(error.retryAfterSeconds));
    return reply.code(statusFor(error)).send({error: error.message});
  }
}

function statusFor(error: SkillCatalogError): 400 | 404 | 429 | 503 {
  switch (error.kind) {
    case "invalid": return 400;
    case "not_found": return 404;
    case "rate_limited": return 429;
    case "unauthorized":
    case "unavailable": return 503;
  }
}
