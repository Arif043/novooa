import { type FastifyInstance, type FastifyReply, type FastifyRequest } from "fastify";
import { randomUUID } from "node:crypto";
import { type ApplicationLogger } from "../../../../shared/logging/application-logger.js";
import { InstallTeamModel } from "../../domain/usecases/install-team-model.js";
import { type TeamModelCatalog } from "../../domain/repositories/model-catalog.js";
import { type ModelArtifactReference } from "../../domain/entities/model-artifact-reference.js";
import { type ModelArtifactPublication } from "../../domain/repositories/model-artifact-publisher.js";
import { type ModelArtifactDistribution } from "../model-artifact-distribution.js";
import { LocalModelArtifactPublisher } from "./local-model-artifact-publisher.js";
import { LocalModelArtifactUploadStore, type StagedModelArtifact } from "./local-model-artifact-upload-store.js";
import { type ModelContractValidator } from "./python-model-contract-validator.js";
import { systemModelEntry, systemModelManifestFromUnknown } from "../cli/system-model-manifest.js";
import { type LocalRuntimeRealtimeNotifier } from "../../../../shared/local/local-runtime-realtime-notifier.js";
import { type RuntimeSystemModelCatalog } from "./runtime-system-model-catalog.js";
type PendingModelImport = {
  manifest: ReturnType<typeof systemModelManifestFromUnknown>;
};
export class LocalModelCatalogHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalModelCatalogHttpHandler): void {
    http.get("/v1/ml-models", (request, reply) => current().list(reply));
    http.get("/v1/ml-models/catalog", (request, reply) => current().listGlobal(reply));
    http.post<{Params: {modelId: string}}>("/v1/ml-models/catalog/:modelId/install", (request, reply) => current().installGlobal(request.params.modelId, reply));
    http.post("/v1/ml-models/imports", (request, reply) => current().createImport(request.body, reply));
    http.delete<{Params: {modelId: string}}>("/v1/ml-models/:modelId", (request, reply) => current().remove(request.params.modelId, reply));
    http.put<{Params: {importId: string}}>("/v1/ml-models/imports/:importId/artifact", (request, reply) => current().uploadArtifact(request.params.importId, request, reply));
  }
  constructor(private readonly catalog: TeamModelCatalog, private readonly artifactPublisher: LocalModelArtifactPublisher, private readonly uploadStore: LocalModelArtifactUploadStore, private readonly teamId: string, private readonly contractValidator: ModelContractValidator, private readonly logger: ApplicationLogger, private readonly notifier: LocalRuntimeRealtimeNotifier, private readonly globalCatalog?: RuntimeSystemModelCatalog, private readonly artifactDownloader?: ModelArtifactDownloader) {
    this.installer = new InstallTeamModel(artifactPublisher, catalog);
  }
  private readonly installer: InstallTeamModel;
  private readonly imports = new Map<string, PendingModelImport>();
  private async list(reply: FastifyReply): Promise<FastifyReply> {
    return reply.code(200).send({ items: await this.catalog.listAvailableFor(this.teamId) });
  }
  private async listGlobal(reply: FastifyReply): Promise<FastifyReply> {
    if (this.globalCatalog === undefined)
      return this.unavailableGlobalCatalog(reply);
    try {
      const models = await this.globalCatalog.list();
      return reply.code(200).send({ items: models.map((model) => model.entry) });
    }
    catch (error) {
      return this.failure("catalog_list_failed", error, reply);
    }
  }
  private async installGlobal(modelId: string, reply: FastifyReply): Promise<FastifyReply> {
    if (this.globalCatalog === undefined || this.artifactDownloader === undefined) {
      return this.unavailableGlobalCatalog(reply);
    }
    try {
      const model = await this.globalCatalog.find(modelId);
      if (model === null || model.entry.scope.type !== "system") {
        return reply.code(404).send({ error: "Der globale Katalogeintrag wurde nicht gefunden." });
      }
      const { entry, distribution } = model;
      await validateContract(this.contractValidator, entry.contract);
      const artifact = await this.artifactDownloader.download(entry.artifactReference, distribution);
      const installed = await this.installer.execute({
        entry: { ...entry, scope: { type: "team", teamId: this.teamId } },
        artifact,
      });
      this.logger.info("local_model_catalog.installed_from_catalog", { modelId, teamId: this.teamId });
      this.notifier.publish("model-catalog");
      return reply.code(201).send(installed);
    }
    catch (error) {
      return this.failure("catalog_install_failed", error, reply);
    }
  }
  private unavailableGlobalCatalog(reply: FastifyReply): FastifyReply {
    return reply.code(503).send({ error: "Der globale Modellkatalog ist nicht verfügbar." });
  }
  private async createImport(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const manifest = systemModelManifestFromUnknown(record(body).manifest);
      const importId = randomUUID();
      this.imports.set(importId, { manifest });
      return reply.code(201).send({ importId });
    }
    catch (error) {
      return this.failure("create_failed", error, reply);
    }
  }
  private async uploadArtifact(importId: string, request: FastifyRequest, reply: FastifyReply): Promise<FastifyReply> {
    const pending = this.imports.get(importId);
    if (pending === undefined)
      return reply.code(404).send({ error: "Der Modellimport wurde nicht gefunden." });
    if (!isOnnxContentType(request.headers))
      return reply.code(415).send({ error: "Der Upload erwartet application/onnx." });
    let staged: StagedModelArtifact | null = null;
    try {
      staged = await this.uploadStore.stage(importId, request.raw, contentLength(request.headers));
      const entry = systemModelEntry(pending.manifest, artifactReferenceFor(pending.manifest, staged));
      await validateContract(this.contractValidator, entry.contract);
      const installed = await this.installer.execute({
        entry: { ...entry, scope: { type: "team", teamId: this.teamId } },
        artifact: { reference: entry.artifactReference, content: this.uploadStore.contentFor(staged) },
      });
      this.imports.delete(importId);
      this.logger.info("local_model_catalog.installed", { modelId: installed.id, teamId: this.teamId });
      this.notifier.publish("model-catalog");
      return reply.code(201).send(installed);
    }
    catch (error) {
      return this.failure("upload_failed", error, reply);
    }
    finally {
      if (staged !== null)
        await this.uploadStore.discard(staged);
    }
  }
  private async remove(modelId: string, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const entry = await this.catalog.findAvailableFor(this.teamId, modelId);
      if (entry === null || entry.scope.type !== "team" || entry.scope.teamId !== this.teamId) {
        return reply.code(404).send({ error: "Der lokale Katalogeintrag wurde nicht gefunden." });
      }
      await this.artifactPublisher.remove(entry.artifactReference);
      const removed = await this.catalog.removeTeamEntry(this.teamId, modelId);
      if (!removed)
        return reply.code(404).send({ error: "Der lokale Katalogeintrag wurde nicht gefunden." });
      this.logger.info("local_model_catalog.removed", { modelId, teamId: this.teamId });
      this.notifier.publish("model-catalog");
      return reply.code(204).send();
    }
    catch (error) {
      return this.failure("remove_failed", error, reply);
    }
  }
  private failure(event: string, error: unknown, reply: FastifyReply): FastifyReply {
    if (error instanceof LocalModelCatalogRequestError || error instanceof Error && isValidationError(error)) {
      return reply.code(400).send({ error: error.message });
    }
    this.logger.exception("local_model_catalog." + event, error, { teamId: this.teamId });
    return reply.code(500).send({ error: "Der Modellkatalog konnte nicht aktualisiert werden." });
  }
}
function artifactReferenceFor(manifest: ReturnType<typeof systemModelManifestFromUnknown>, staged: StagedModelArtifact) {
  return { artifactId: manifest.artifact.artifactId, versionId: manifest.artifact.versionId, format: "onnx" as const, contentType: "application/onnx", sizeBytes: staged.sizeBytes, sha256: staged.sha256 };
}
async function validateContract(validator: ModelContractValidator, contract: Parameters<ModelContractValidator["validate"]>[0]): Promise<void> {
  try {
    await validator.validate(contract);
  }
  catch (error) {
    throw new LocalModelCatalogRequestError(errorMessage(error));
  }
}
function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value))
    return value as Record<string, unknown>;
  throw new LocalModelCatalogRequestError("Der Modellimport erwartet ein Objekt.");
}
function isOnnxContentType(headers: FastifyRequest["headers"]): boolean {
  const value = headers["content-type"];
  const contentType = Array.isArray(value) ? value[0] : value;
  return contentType?.split(";", 1)[0] === "application/onnx";
}
function contentLength(headers: FastifyRequest["headers"]): number | null {
  const value = headers["content-length"];
  const text = Array.isArray(value) ? value[0] : value;
  if (text === undefined)
    return null;
  const length = Number(text);
  if (!Number.isSafeInteger(length) || length < 0)
    throw new LocalModelCatalogRequestError("Die Uploadgröße ist ungültig.");
  return length;
}
function isValidationError(error: Error): boolean {
  return error.message === "Diese lokale Modellversion ist bereits installiert.";
}
class LocalModelCatalogRequestError extends Error {
}
function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : "Das Manifest ist ungültig.";
}
export interface ModelArtifactDownloader {
  download(reference: ModelArtifactReference, distribution: ModelArtifactDistribution): Promise<ModelArtifactPublication>;
}
