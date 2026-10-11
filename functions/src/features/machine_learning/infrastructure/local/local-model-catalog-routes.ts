import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {IdParams, ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type LocalRuntimeWorkspaceContext} from "../../../../shared/local/local-runtime-workspace-context.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type TeamModelCatalog} from "../../domain/repositories/model-catalog.js";
import {InstallTeamModel} from "../../domain/usecases/install-team-model.js";
import {type ModelArtifactPublication} from "../../domain/repositories/model-artifact-publisher.js";
import {type LocalModelArtifactPublisher} from "./local-model-artifact-publisher.js";
import {type LocalModelArtifactUploadStore} from "./local-model-artifact-upload-store.js";
import {validateContract} from "./local-model-catalog-support.js";
import {modelImportRoutes} from "./local-model-import-routes.js";
import {entryDto, failures, guarded, ModelEntry} from "./local-model-route-support.js";
import {type ModelContractValidator} from "./python-model-contract-validator.js";

export type ModelCatalogRoutesOptions = {
  catalog: TeamModelCatalog;
  artifactPublisher: LocalModelArtifactPublisher;
  uploadStore: LocalModelArtifactUploadStore;
  contractValidator: ModelContractValidator;
  notifier: {publish(topic: string): void};
};

const CacheStatus = Type.Object({
  modelId: Type.String(), state: Type.String(), message: Type.Optional(Type.String()),
});
const ModelParams = IdParams("modelId");

export const modelCatalogRoutes: FastifyPluginAsyncTypebox<ModelCatalogRoutesOptions> = async (app, options) => {
  const installer = new InstallTeamModel(options.artifactPublisher, options.catalog);
  const install = async (workspace: LocalRuntimeWorkspaceContext, entry: ModelCatalogEntry, artifact: ModelArtifactPublication) => {
    await validateContract(options.contractValidator, entry.contract);
    const installed = await installer.execute({entry: {...entry, scope: {type: "team", teamId: workspace.teamId}, origin: "import"}, artifact});
    options.notifier.publish("model-catalog");
    return installed;
  };
  await app.register(modelImportRoutes, {uploadStore: options.uploadStore, install});

  app.get("/v1/ml-models", {schema: {response: {200: ItemsOf(ModelEntry)}}},
    async (request) => ({items: (await options.catalog.listAvailableFor(request.workspace.teamId)).map(entryDto)}));

  app.get("/v1/ml-models/catalog", {schema: {response: {...failures, 200: ItemsOf(ModelEntry)}}}, async (request, reply) => {
    const {systemModelCatalog} = request.workspace;
    if (systemModelCatalog === undefined) return reply.code(503).send(unavailableCatalog);
    return guarded(request.workspace, "catalog_list_failed", reply, async () =>
      ({items: (await systemModelCatalog.list()).map((model) => entryDto(model.entry))}));
  });

  /**
   * Lädt ein Katalogmodell im Hintergrund in den Cache. 200, wenn es schon gecacht ist; sonst 202 —
   * der Fortschritt kommt über `/cache-status` und das Realtime-Thema `model-cache`.
   */
  app.post("/v1/ml-models/catalog/:modelId/cache", {schema: {params: ModelParams, response: {...failures, 200: CacheStatus, 202: CacheStatus}}},
    async (request, reply) => {
      const {workspace} = request;
      const {modelId} = request.params;
      if (workspace.modelCache === undefined || workspace.systemModelCatalog === undefined) {
        return reply.code(503).send(unavailableCatalog);
      }
      const modelCache = workspace.modelCache;
      const systemCatalog = workspace.systemModelCatalog;
      return guarded(workspace, "cache_failed", reply, async () => {
        if (await options.catalog.findAvailableFor(workspace.teamId, modelId) !== null) {
          return reply.code(200).send({modelId, state: "cached"});
        }
        if (await systemCatalog.find(modelId) === null) {
          return reply.code(404).send({error: "Der globale Katalogeintrag wurde nicht gefunden."});
        }
        modelCache.jobs.start(modelId);
        return reply.code(202).send({modelId, state: "downloading"});
      });
    });

  app.get("/v1/ml-models/cache-status", {schema: {response: {200: ItemsOf(CacheStatus)}}},
    async (request) => ({items: request.workspace.modelCache?.jobs.list() ?? []}));

  app.delete("/v1/ml-models/:modelId", {schema: {params: ModelParams, response: {...failures, 204: Type.Null()}}},
    async (request, reply) => guarded(request.workspace, "remove_failed", reply, async () => {
      const {teamId} = request.workspace;
      const entry = await options.catalog.findAvailableFor(teamId, request.params.modelId);
      if (entry === null || entry.scope.type !== "team" || entry.scope.teamId !== teamId) return reply.code(404).send(missingEntry);
      if (!await options.catalog.removeTeamEntry(teamId, request.params.modelId)) return reply.code(404).send(missingEntry);
      // Gibt Speicher frei, solange kein anderer Eintrag dieselbe Artefaktversion nutzt.
      const remaining = await options.catalog.listAvailableFor(teamId);
      if (!remaining.some((other) => sameArtifact(other, entry))) await options.artifactPublisher.remove(entry.artifactReference);
      request.workspace.logger.info("local_model_catalog.removed", {modelId: request.params.modelId, teamId});
      options.notifier.publish("model-catalog");
      return reply.code(204).send(null);
    }));
};

function sameArtifact(left: ModelCatalogEntry, right: ModelCatalogEntry): boolean {
  return left.artifactReference.artifactId === right.artifactReference.artifactId &&
    left.artifactReference.versionId === right.artifactReference.versionId;
}

const unavailableCatalog = {error: "Der globale Modellkatalog ist nicht verfügbar."};
const missingEntry = {error: "Der lokale Katalogeintrag wurde nicht gefunden."};
