import {randomUUID} from "node:crypto";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
  type LocalRuntimeStreamRequest,
  type LocalRuntimeStreamRequestHandler,
} from "../../../../shared/local/local-runtime-http-server.js";
import {InstallTeamModel} from "../../domain/usecases/install-team-model.js";
import {type TeamModelCatalog} from "../../domain/repositories/model-catalog.js";
import {LocalModelArtifactPublisher} from "./local-model-artifact-publisher.js";
import {LocalModelArtifactUploadStore, type StagedModelArtifact} from "./local-model-artifact-upload-store.js";
import {type ModelContractValidator} from "./python-model-contract-validator.js";
import {systemModelEntry, systemModelManifestFromUnknown} from "../cli/system-model-manifest.js";
import {type LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";

type PendingModelImport = {
  manifest: ReturnType<typeof systemModelManifestFromUnknown>;
};

export class LocalModelCatalogHttpHandler implements LocalRuntimeRequestHandler, LocalRuntimeStreamRequestHandler {
  constructor(
    private readonly catalog: TeamModelCatalog,
    private readonly artifactPublisher: LocalModelArtifactPublisher,
    private readonly uploadStore: LocalModelArtifactUploadStore,
    private readonly teamId: string,
    private readonly contractValidator: ModelContractValidator,
    private readonly logger: ApplicationLogger,
    private readonly notifier: LocalRuntimeRealtimeNotifier,
  ) {
    this.installer = new InstallTeamModel(artifactPublisher, catalog);
  }

  private readonly installer: InstallTeamModel;
  private readonly imports = new Map<string, PendingModelImport>();

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (request.url === "/v1/ml-models" && request.method === "GET") return this.list();
    if (request.url === "/v1/ml-models/imports" && request.method === "POST") return this.createImport(request.body);
    const modelId = modelIdFrom(request.url);
    if (modelId !== null && request.method === "DELETE") return this.remove(modelId);
    return null;
  }

  async handleStream(request: LocalRuntimeStreamRequest): Promise<LocalRuntimeResponse | null> {
    const importId = importIdFrom(request.url);
    if (importId === null || request.method !== "PUT") return null;
    return this.uploadArtifact(importId, request);
  }

  private async list(): Promise<LocalRuntimeResponse> {
    return {body: {items: await this.catalog.listAvailableFor(this.teamId)}, statusCode: 200};
  }

  private async createImport(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const manifest = systemModelManifestFromUnknown(record(body).manifest);
      const importId = randomUUID();
      this.imports.set(importId, {manifest});
      return {body: {importId}, statusCode: 201};
    } catch (error) {
      return this.failure("create_failed", error);
    }
  }

  private async uploadArtifact(importId: string, request: LocalRuntimeStreamRequest): Promise<LocalRuntimeResponse> {
    const pending = this.imports.get(importId);
    if (pending === undefined) return {body: {error: "Der Modellimport wurde nicht gefunden."}, statusCode: 404};
    if (!isOnnxContentType(request.headers)) return {body: {error: "Der Upload erwartet application/onnx."}, statusCode: 415};
    let staged: StagedModelArtifact | null = null;
    try {
      staged = await this.uploadStore.stage(importId, request.body, contentLength(request.headers));
      const entry = systemModelEntry(pending.manifest, artifactReferenceFor(pending.manifest, staged));
      await validateContract(this.contractValidator, entry.contract);
      const installed = await this.installer.execute({
        entry: {...entry, scope: {type: "team", teamId: this.teamId}},
        artifact: {reference: entry.artifactReference, content: this.uploadStore.contentFor(staged)},
      });
      this.imports.delete(importId);
      this.logger.info("local_model_catalog.installed", {modelId: installed.id, teamId: this.teamId});
      this.notifier.publish("model-catalog");
      return {body: installed, statusCode: 201};
    } catch (error) {
      return this.failure("upload_failed", error);
    } finally {
      if (staged !== null) await this.uploadStore.discard(staged);
    }
  }

  private async remove(modelId: string): Promise<LocalRuntimeResponse> {
    try {
      const entry = await this.catalog.findAvailableFor(this.teamId, modelId);
      if (entry === null || entry.scope.type !== "team" || entry.scope.teamId !== this.teamId) {
        return {body: {error: "Der lokale Katalogeintrag wurde nicht gefunden."}, statusCode: 404};
      }
      await this.artifactPublisher.remove(entry.artifactReference);
      const removed = await this.catalog.removeTeamEntry(this.teamId, modelId);
      if (!removed) return {body: {error: "Der lokale Katalogeintrag wurde nicht gefunden."}, statusCode: 404};
      this.logger.info("local_model_catalog.removed", {modelId, teamId: this.teamId});
      this.notifier.publish("model-catalog");
      return {body: {}, statusCode: 204};
    } catch (error) {
      return this.failure("remove_failed", error);
    }
  }

  private failure(event: string, error: unknown): LocalRuntimeResponse {
    if (error instanceof LocalModelCatalogRequestError || error instanceof Error && isValidationError(error)) {
      return {body: {error: error.message}, statusCode: 400};
    }
    this.logger.exception("local_model_catalog." + event, error, {teamId: this.teamId});
    return {body: {error: "Der Modellkatalog konnte nicht aktualisiert werden."}, statusCode: 500};
  }
}

function artifactReferenceFor(manifest: ReturnType<typeof systemModelManifestFromUnknown>, staged: StagedModelArtifact) {
  return {artifactId: manifest.artifact.artifactId, versionId: manifest.artifact.versionId, format: "onnx" as const, contentType: "application/onnx", sizeBytes: staged.sizeBytes, sha256: staged.sha256};
}

async function validateContract(validator: ModelContractValidator, contract: Parameters<ModelContractValidator["validate"]>[0]): Promise<void> {
  try {
    await validator.validate(contract);
  } catch (error) {
    throw new LocalModelCatalogRequestError(errorMessage(error));
  }
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new LocalModelCatalogRequestError("Der Modellimport erwartet ein Objekt.");
}

function modelIdFrom(url: string | undefined): string | null {
  const match = /^\/v1\/ml-models\/([^/]+)$/.exec(new URL(url ?? "/", "http://local-runtime").pathname);
  return match?.[1] ? decodeURIComponent(match[1]) : null;
}

function importIdFrom(url: string | undefined): string | null {
  const match = /^\/v1\/ml-models\/imports\/([0-9a-f-]+)\/artifact$/.exec(new URL(url ?? "/", "http://local-runtime").pathname);
  return match?.[1] ?? null;
}

function isOnnxContentType(headers: LocalRuntimeStreamRequest["headers"]): boolean {
  const value = headers["content-type"];
  const contentType = Array.isArray(value) ? value[0] : value;
  return contentType?.split(";", 1)[0] === "application/onnx";
}

function contentLength(headers: LocalRuntimeStreamRequest["headers"]): number | null {
  const value = headers["content-length"];
  const text = Array.isArray(value) ? value[0] : value;
  if (text === undefined) return null;
  const length = Number(text);
  if (!Number.isSafeInteger(length) || length < 0) throw new LocalModelCatalogRequestError("Die Uploadgröße ist ungültig.");
  return length;
}

function isValidationError(error: Error): boolean {
  return error.message === "Diese lokale Modellversion ist bereits installiert.";
}

class LocalModelCatalogRequestError extends Error {}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : "Das Manifest ist ungültig.";
}
