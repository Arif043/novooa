import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply, type FastifyRequest} from "fastify";
import {randomUUID} from "node:crypto";
import {IdParams} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type LocalRuntimeWorkspaceContext} from "../../../../shared/local/local-runtime-workspace-context.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelArtifactPublication} from "../../domain/repositories/model-artifact-publisher.js";
import {systemModelEntry, systemModelManifestFromUnknown} from "../cli/system-model-manifest.js";
import {type LocalModelArtifactUploadStore, type StagedModelArtifact} from "./local-model-artifact-upload-store.js";
import {artifactReferenceFor, contentLength, requireKnownTags, type SystemModelManifest} from "./local-model-catalog-support.js";
import {entryDto, failures, guarded, ModelEntry} from "./local-model-route-support.js";

export type ModelImportRoutesOptions = {
  uploadStore: LocalModelArtifactUploadStore;
  install(workspace: LocalRuntimeWorkspaceContext, entry: ModelCatalogEntry, artifact: ModelArtifactPublication): Promise<ModelCatalogEntry>;
};

type PendingImport = {manifest: SystemModelManifest; externalData: Map<string, StagedModelArtifact>};

const ExternalDataParams = Type.Object({importId: Type.String(), name: Type.String({pattern: "^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$"})});

/**
 * Ein Import: Manifest anlegen, optional Gewichtsdateien (External Data) hochladen, zuletzt das Modell.
 * Der Modell-Upload installiert alles zusammen; Dateien werden als Datenstrom geschrieben, nie gepuffert.
 */
export const modelImportRoutes: FastifyPluginAsyncTypebox<ModelImportRoutesOptions> = async (app, options) => {
  const imports = new Map<string, PendingImport>();

  app.post("/v1/ml-models/imports", {
    schema: {body: Type.Object({manifest: Type.Unknown()}), response: {...failures, 201: Type.Object({importId: Type.String()})}},
  }, async (request, reply) => guarded(request.workspace, "create_failed", reply, async () => {
    const importId = randomUUID();
    const manifest = systemModelManifestFromUnknown(request.body.manifest);
    // Vor dem Upload: Ein Modell mit unbekannten Tags ließe sich sonst erst nach Gigabytes ablehnen.
    await requireKnownTags(request.workspace.modelTagVocabulary, manifest.tags);
    imports.set(importId, {manifest, externalData: new Map()});
    return reply.code(201).send({importId});
  }));

  app.put("/v1/ml-models/imports/:importId/external-data/:name", {schema: {params: ExternalDataParams, response: {...failures, 201: Type.Object({name: Type.String()})}}},
    async (request, reply) => {
      const pending = imports.get(request.params.importId);
      if (pending === undefined) return reply.code(404).send(missingImport);
      if (!isOnnxUpload(request)) return reply.code(415).send(wrongType);
      if (request.params.name === "model.onnx") return reply.code(400).send({error: "Der Name model.onnx ist dem Modell vorbehalten."});
      return guarded(request.workspace, "upload_failed", reply, async () => {
        const staged = await stage(options.uploadStore, request, request.params.importId, request.params.name);
        pending.externalData.set(request.params.name, staged);
        return reply.code(201).send({name: request.params.name});
      });
    });

  app.put("/v1/ml-models/imports/:importId/artifact", {schema: {params: IdParams("importId"), response: {...failures, 201: ModelEntry}}},
    async (request, reply) => {
      const pending = imports.get(request.params.importId);
      if (pending === undefined) return reply.code(404).send(missingImport);
      if (!isOnnxUpload(request)) return reply.code(415).send(wrongType);
      imports.delete(request.params.importId);
      return installUpload(options, request, reply, pending);
    });
};

async function installUpload(
  options: ModelImportRoutesOptions, request: FastifyRequest<{Params: {importId: string}}>, reply: FastifyReply, pending: PendingImport,
) {
  return guarded(request.workspace, "upload_failed", reply, async () => {
    const installed = await stageAndInstall(options, request, pending).finally(() => options.uploadStore.discard(request.params.importId));
    request.workspace.logger.info("local_model_catalog.installed", {modelId: installed.id, teamId: request.workspace.teamId});
    return reply.code(201).send(entryDto(installed));
  });
}

/** Die Zwischenablage wird verworfen, bevor die Antwort rausgeht — auch wenn die Installation scheitert. */
async function stageAndInstall(
  options: ModelImportRoutesOptions, request: FastifyRequest<{Params: {importId: string}}>, pending: PendingImport,
): Promise<ModelCatalogEntry> {
  const staged = await stage(options.uploadStore, request, request.params.importId, "model.onnx");
  const entry = systemModelEntry(pending.manifest, artifactReferenceFor(pending.manifest, staged, pending.externalData));
  return options.install(request.workspace, entry, publicationFor(options.uploadStore, entry, staged, pending));
}

function publicationFor(
  store: LocalModelArtifactUploadStore, entry: ModelCatalogEntry, staged: StagedModelArtifact, pending: PendingImport,
): ModelArtifactPublication {
  const externalData = (entry.artifactReference.externalData ?? []).map((reference) => ({
    reference, content: store.contentFor(pending.externalData.get(reference.name)!),
  }));
  return {reference: entry.artifactReference, content: store.contentFor(staged), ...(externalData.length > 0 ? {externalData} : {})};
}

function stage(store: LocalModelArtifactUploadStore, request: FastifyRequest, importId: string, fileName: string) {
  return store.stage(importId, fileName, request.raw, contentLength(request.headers["content-length"]));
}

function isOnnxUpload(request: FastifyRequest): boolean {
  return request.headers["content-type"]?.split(";", 1)[0] === "application/onnx";
}

const missingImport = {error: "Der Modellimport wurde nicht gefunden."};
const wrongType = {error: "Der Upload erwartet application/onnx."};
