import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type ScriptPackageJobs} from "./script-package-jobs.js";

export type ScriptPackageRoutesOptions = {jobs: ScriptPackageJobs | undefined};

const EnvironmentStatus = Type.Object({
  packages: Type.Array(Type.String()),
  state: Type.String(),
  reason: Type.Optional(Type.String()),
  detail: Type.Optional(Type.String()),
  sizeBytes: Type.Optional(Type.Number()),
});
const InstallRequest = Type.Object({
  packages: Type.Array(Type.String({minLength: 1, maxLength: 200}), {minItems: 1, maxItems: 50}),
});
const Unavailable = Type.Object({error: Type.String()});
const unavailable = {error: "Python-Pakete sind in dieser Runtime nicht eingerichtet (SCRIPT_PACKAGES_URL)."};

/**
 * Paketumgebungen der Script-Bausteine. Installiert wird nur auf ausdrücklichen Wunsch (POST);
 * der Fortschritt kommt über `GET` und das Realtime-Thema `script-packages`.
 */
export const scriptPackageRoutes: FastifyPluginAsyncTypebox<ScriptPackageRoutesOptions> = async (app, {jobs}) => {
  app.get("/v1/script-packages", {schema: {response: {200: ItemsOf(EnvironmentStatus), 503: Unavailable}}},
    async (_request, reply) => {
      if (jobs === undefined) return reply.code(503).send(unavailable);
      return {items: await jobs.list()};
    });

  app.post("/v1/script-packages", {schema: {body: InstallRequest, response: {202: EnvironmentStatus, 503: Unavailable}}},
    async (request, reply) => {
      if (jobs === undefined) return reply.code(503).send(unavailable);
      const packages = jobs.start(request.body.packages);
      return reply.code(202).send({packages, state: "installing"});
    });
};
