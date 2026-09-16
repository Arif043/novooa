import {createHash} from "node:crypto";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {InstallTeamModel} from "../../domain/usecases/install-team-model.js";
import {type TeamModelCatalog} from "../../domain/repositories/model-catalog.js";
import {LocalModelArtifactPublisher} from "./local-model-artifact-publisher.js";
import {type ModelContractValidator} from "./python-model-contract-validator.js";
import {systemModelEntry, systemModelManifestFromUnknown} from "../cli/system-model-manifest.js";

export class LocalModelCatalogHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly catalog: TeamModelCatalog,
    private readonly artifactPublisher: LocalModelArtifactPublisher,
    private readonly teamId: string,
    private readonly contractValidator: ModelContractValidator,
    private readonly logger: ApplicationLogger,
  ) {
    this.installer = new InstallTeamModel(artifactPublisher, catalog);
  }

  private readonly installer: InstallTeamModel;

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (request.url === "/v1/ml-models" && request.method === "GET") return this.list();
    if (request.url === "/v1/ml-models" && request.method === "POST") return this.install(request.body);
    const modelId = modelIdFrom(request.url);
    if (modelId !== null && request.method === "DELETE") return this.remove(modelId);
    return null;
  }

  private async list(): Promise<LocalRuntimeResponse> {
    return {body: {items: await this.catalog.listAvailableFor(this.teamId)}, statusCode: 200};
  }

  private async install(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const input = importFrom(body);
      const entry = systemModelEntry(input.manifest, input.artifact.reference);
      await validateContract(this.contractValidator, entry.contract);
      const teamEntry = {...entry, scope: {type: "team" as const, teamId: this.teamId}};
      const installed = await this.installer.execute({entry: teamEntry, artifact: input.artifact});
      this.logger.info("local_model_catalog.installed", {modelId: installed.id, teamId: this.teamId});
      return {body: installed, statusCode: 201};
    } catch (error) {
      return this.failure("install_failed", error);
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
      return {body: {}, statusCode: 204};
    } catch (error) {
      return this.failure("remove_failed", error);
    }
  }

  private failure(event: string, error: unknown): LocalRuntimeResponse {
    if (error instanceof LocalModelCatalogRequestError) {
      return {body: {error: error.message}, statusCode: 400};
    }
    if (error instanceof Error && isValidationError(error)) {
      return {body: {error: error.message}, statusCode: 400};
    }
    this.logger.exception(`local_model_catalog.${event}`, error, {teamId: this.teamId});
    return {body: {error: "Der Modellkatalog konnte nicht aktualisiert werden."}, statusCode: 500};
  }
}

function importFrom(value: unknown) {
  try {
    const input = record(value);
    const manifest = systemModelManifestFromUnknown(input.manifest);
    const bytes = artifactBytes(input.artifactBase64);
    const reference = {
      artifactId: manifest.artifact.artifactId,
      versionId: manifest.artifact.versionId,
      format: "onnx" as const,
      contentType: "application/onnx",
      sizeBytes: bytes.length,
      sha256: createHash("sha256").update(bytes).digest("hex"),
    };
    return {manifest, artifact: {reference, content: byteChunks(bytes)}};
  } catch (error) {
    if (error instanceof LocalModelCatalogRequestError) throw error;
    throw new LocalModelCatalogRequestError(errorMessage(error));
  }
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

function artifactBytes(value: unknown): Buffer {
  if (typeof value !== "string" || value.length === 0 || !/^[A-Za-z0-9+/]*={0,2}$/.test(value)) {
    throw new LocalModelCatalogRequestError("Die ONNX-Datei ist ungültig.");
  }
  const bytes = Buffer.from(value, "base64");
  if (bytes.length === 0 || bytes.toString("base64") !== value) {
    throw new LocalModelCatalogRequestError("Die ONNX-Datei ist ungültig.");
  }
  return bytes;
}

async function* byteChunks(bytes: Uint8Array): AsyncGenerator<Uint8Array> {
  yield bytes;
}

function modelIdFrom(url: string | undefined): string | null {
  const match = /^\/v1\/ml-models\/([^/]+)$/.exec(new URL(url ?? "/", "http://local-runtime").pathname);
  return match?.[1] ? decodeURIComponent(match[1]) : null;
}

function isValidationError(error: Error): boolean {
  return error.message === "Diese lokale Modellversion ist bereits installiert.";
}

class LocalModelCatalogRequestError extends Error {}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : "Das Manifest ist ungültig.";
}
