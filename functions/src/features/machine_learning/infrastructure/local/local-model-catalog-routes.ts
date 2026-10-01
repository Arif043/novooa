import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply} from "fastify";
import {randomUUID} from "node:crypto";
import {ErrorResponse, IdParams, ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type LocalRuntimeWorkspaceContext} from "../../../../shared/local/local-runtime-workspace-context.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type TeamModelCatalog} from "../../domain/repositories/model-catalog.js";
import {InstallTeamModel} from "../../domain/usecases/install-team-model.js";
import {systemModelEntry, systemModelManifestFromUnknown} from "../cli/system-model-manifest.js";
import {type LocalModelArtifactPublisher} from "./local-model-artifact-publisher.js";
import {type LocalModelArtifactUploadStore, type StagedModelArtifact} from "./local-model-artifact-upload-store.js";
import {
  artifactReferenceFor, contentLength, isRequestError, type ModelArtifactDownloader, type SystemModelManifest,
  validateContract,
} from "./local-model-catalog-support.js";
import {type ModelContractValidator} from "./python-model-contract-validator.js";

export type ModelCatalogRoutesOptions = {
  catalog: TeamModelCatalog;
  artifactPublisher: LocalModelArtifactPublisher;
  uploadStore: LocalModelArtifactUploadStore;
  contractValidator: ModelContractValidator;
  notifier: {publish(topic: string): void};
  artifactDownloader?: ModelArtifactDownloader;
};

const ModelEntry = Type.Object({
  id: Type.String(), title: Type.String(), description: Type.String(), tags: Type.Array(Type.String()),
  scope: Type.Unknown(), runtime: Type.String(), artifactReference: Type.Unknown(), contract: Type.Unknown(),
});
const failures = {400: ErrorResponse, 404: ErrorResponse, 415: ErrorResponse, 500: ErrorResponse, 503: ErrorResponse};
const ModelParams = IdParams("modelId");

export const modelCatalogRoutes: FastifyPluginAsyncTypebox<ModelCatalogRoutesOptions> = async (app, options) => {
  const installer = new InstallTeamModel(options.artifactPublisher, options.catalog);
  /** Prozessweit: ein Import besteht aus Manifest-Anfrage und anschließendem Artefakt-Upload. */
  const imports = new Map<string, SystemModelManifest>();
  const install = async (workspace: LocalRuntimeWorkspaceContext, entry: ModelCatalogEntry, artifact: Parameters<InstallTeamModel["execute"]>[0]["artifact"]) => {
    await validateContract(options.contractValidator, entry.contract);
    const installed = await installer.execute({entry: {...entry, scope: {type: "team", teamId: workspace.teamId}}, artifact});
    options.notifier.publish("model-catalog");
    return installed;
  };

  app.get("/v1/ml-models", {schema: {response: {200: ItemsOf(ModelEntry)}}},
    async (request) => ({items: (await options.catalog.listAvailableFor(request.workspace.teamId)).map(entryDto)}));

  app.get("/v1/ml-models/catalog", {schema: {response: {...failures, 200: ItemsOf(ModelEntry)}}}, async (request, reply) => {
    const {systemModelCatalog} = request.workspace;
    if (systemModelCatalog === undefined) return reply.code(503).send(unavailableCatalog);
    return guarded(request.workspace, "catalog_list_failed", reply, async () =>
      ({items: (await systemModelCatalog.list()).map((model) => entryDto(model.entry))}));
  });

  app.post("/v1/ml-models/catalog/:modelId/install", {schema: {params: ModelParams, response: {...failures, 201: ModelEntry}}},
    async (request, reply) => {
      const {workspace} = request;
      const downloader = options.artifactDownloader;
      if (workspace.systemModelCatalog === undefined || downloader === undefined) return reply.code(503).send(unavailableCatalog);
      const systemCatalog = workspace.systemModelCatalog;
      return guarded(workspace, "catalog_install_failed", reply, async () => {
        const model = await systemCatalog.find(request.params.modelId);
        if (model === null || model.entry.scope.type !== "system") {
          return reply.code(404).send({error: "Der globale Katalogeintrag wurde nicht gefunden."});
        }
        const artifact = await downloader.download(model.entry.artifactReference, model.distribution);
        workspace.logger.info("local_model_catalog.installed_from_catalog", {modelId: model.entry.id, teamId: workspace.teamId});
        return reply.code(201).send(entryDto(await install(workspace, model.entry, artifact)));
      });
    });

  app.post("/v1/ml-models/imports", {
    schema: {body: Type.Object({manifest: Type.Unknown()}), response: {...failures, 201: Type.Object({importId: Type.String()})}},
  }, async (request, reply) => guarded(request.workspace, "create_failed", reply, async () => {
    const importId = randomUUID();
    imports.set(importId, systemModelManifestFromUnknown(request.body.manifest));
    return reply.code(201).send({importId});
  }));

  app.put("/v1/ml-models/imports/:importId/artifact", {schema: {params: IdParams("importId"), response: {...failures, 201: ModelEntry}}},
    async (request, reply) => {
      const manifest = imports.get(request.params.importId);
      if (manifest === undefined) return reply.code(404).send({error: "Der Modellimport wurde nicht gefunden."});
      if (request.headers["content-type"]?.split(";", 1)[0] !== "application/onnx") {
        return reply.code(415).send({error: "Der Upload erwartet application/onnx."});
      }
      let staged: StagedModelArtifact | null = null;
      return guarded(request.workspace, "upload_failed", reply, async () => {
        staged = await options.uploadStore.stage(request.params.importId, request.raw, contentLength(request.headers["content-length"]));
        const entry = systemModelEntry(manifest, artifactReferenceFor(manifest, staged));
        const installed = await install(request.workspace, entry, {reference: entry.artifactReference, content: options.uploadStore.contentFor(staged)});
        imports.delete(request.params.importId);
        request.workspace.logger.info("local_model_catalog.installed", {modelId: installed.id, teamId: request.workspace.teamId});
        return reply.code(201).send(entryDto(installed));
      }).finally(async () => { if (staged !== null) await options.uploadStore.discard(staged); });
    });

  app.delete("/v1/ml-models/:modelId", {schema: {params: ModelParams, response: {...failures, 204: Type.Null()}}},
    async (request, reply) => guarded(request.workspace, "remove_failed", reply, async () => {
      const {teamId} = request.workspace;
      const entry = await options.catalog.findAvailableFor(teamId, request.params.modelId);
      if (entry === null || entry.scope.type !== "team" || entry.scope.teamId !== teamId) return reply.code(404).send(missingEntry);
      await options.artifactPublisher.remove(entry.artifactReference);
      if (!await options.catalog.removeTeamEntry(teamId, request.params.modelId)) return reply.code(404).send(missingEntry);
      request.workspace.logger.info("local_model_catalog.removed", {modelId: request.params.modelId, teamId});
      options.notifier.publish("model-catalog");
      return reply.code(204).send(null);
    }));
};

function entryDto(entry: ModelCatalogEntry) {
  return {...entry, tags: [...entry.tags]};
}

const unavailableCatalog = {error: "Der globale Modellkatalog ist nicht verfügbar."};
const missingEntry = {error: "Der lokale Katalogeintrag wurde nicht gefunden."};

/** Fachliche Fehler als 400 mit Meldung, alles andere protokolliert als 500. */
async function guarded<T>(
  workspace: LocalRuntimeWorkspaceContext, event: string, reply: FastifyReply, action: () => Promise<T>,
): Promise<T | FastifyReply> {
  try {
    return await action();
  } catch (error) {
    if (isRequestError(error)) return reply.code(400).send({error: error.message});
    workspace.logger.exception(`local_model_catalog.${event}`, error, {teamId: workspace.teamId});
    return reply.code(500).send({error: "Der Modellkatalog konnte nicht aktualisiert werden."});
  }
}
