import {type FastifyInstance, type FastifyReply, type FastifyRequest} from "fastify";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {TransferCategorySelection, type TransferCategory, type TransferCounts} from "../../domain/entities/transfer-category.js";
import {InvalidTransferArchiveError, InvalidTransferRequestError} from "../../domain/entities/transfer-errors.js";
import {type ExportWorkspace} from "../../domain/usecases/export-workspace.js";
import {type ImportWorkspace} from "../../domain/usecases/import-workspace.js";
import {type InspectWorkspaceImport} from "../../domain/usecases/inspect-workspace-import.js";
import {FflateTransferArchiveReader} from "../zip/fflate-transfer-archive-reader.js";
import {FflateTransferArchiveWriter} from "../zip/fflate-transfer-archive-writer.js";
import {
  type LocalTransferUploadStore,
  type StagedTransferUpload,
  TransferUploadTooLargeError,
} from "./local-transfer-upload-store.js";

export type WorkspaceTransferHttpDependencies = {
  exportWorkspace: ExportWorkspace;
  inspectImport: InspectWorkspaceImport;
  importWorkspace: ImportWorkspace;
  uploads: LocalTransferUploadStore;
  teamId: string;
  notifier: {publish(topic: string): void};
  logger: ApplicationLogger;
};

const realtimeTopics: Record<TransferCategory, readonly string[]> = {
  files: ["files", "folders"], data: [], knowledge: ["knowledge-notes"], tasks: ["tasks"],
};

export class LocalWorkspaceTransferHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalWorkspaceTransferHttpHandler): void {
    http.post("/v1/transfer/export", (request, reply) => current().exportArchive(request.body, reply));
    http.post("/v1/transfer/imports", (request, reply) => current().stageImport(request, reply));
    http.post<{Params: {importId: string}}>("/v1/transfer/imports/:importId/apply",
      (request, reply) => current().applyImport(request.params.importId, request.body, reply));
    http.delete<{Params: {importId: string}}>("/v1/transfer/imports/:importId",
      (request, reply) => current().discardImport(request.params.importId, reply));
  }

  constructor(private readonly dependencies: WorkspaceTransferHttpDependencies) {}

  private async exportArchive(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const selection = TransferCategorySelection.from(categoriesOf(body));
      const writer = new FflateTransferArchiveWriter();
      void this.dependencies.exportWorkspace.execute({teamId: this.dependencies.teamId, selection, writer})
        .then(() => writer.finish(), (error: unknown) => this.abortExport(writer, error));
      return reply.code(200).type("application/zip")
        .header("content-disposition", `attachment; filename="${exportFileName(new Date())}"`).send(writer.output);
    } catch (error) {
      return this.failure("export_failed", error, reply);
    }
  }

  private async stageImport(request: FastifyRequest, reply: FastifyReply): Promise<FastifyReply> {
    if (request.headers["content-type"]?.split(";", 1)[0] !== "application/zip") {
      return reply.code(415).send({error: "Der Import erwartet eine ZIP-Datei (application/zip)."});
    }
    let upload: StagedTransferUpload | undefined;
    try {
      upload = await this.dependencies.uploads.stage(request.raw, contentLength(request));
      const manifest = await this.dependencies.inspectImport.execute(new FflateTransferArchiveReader(upload.path));
      return reply.code(201).send({importId: upload.id, manifest});
    } catch (error) {
      await this.dependencies.uploads.discard(upload);
      return this.failure("import_upload_failed", error, reply);
    }
  }

  private async applyImport(importId: string, body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    let upload: StagedTransferUpload | undefined;
    try {
      const selection = TransferCategorySelection.from(categoriesOf(body));
      upload = await this.dependencies.uploads.take(importId);
      if (upload === undefined) return reply.code(404).send({error: "Der Import ist abgelaufen. Bitte lade die Datei erneut hoch."});
      const imported = await this.dependencies.importWorkspace.execute({
        teamId: this.dependencies.teamId, selection, reader: new FflateTransferArchiveReader(upload.path),
      });
      this.announce(imported);
      return reply.code(200).send({imported});
    } catch (error) {
      return this.failure("import_failed", error, reply);
    } finally {
      await this.dependencies.uploads.discard(upload);
    }
  }

  private async discardImport(importId: string, reply: FastifyReply): Promise<FastifyReply> {
    await this.dependencies.uploads.discard(await this.dependencies.uploads.take(importId));
    return reply.code(204).send();
  }

  private announce(imported: TransferCounts): void {
    const categories = Object.keys(imported) as TransferCategory[];
    for (const topic of new Set(categories.flatMap((category) => realtimeTopics[category]))) {
      this.dependencies.notifier.publish(topic);
    }
    this.dependencies.logger.info("workspace_transfer.imported", {teamId: this.dependencies.teamId, ...imported});
  }

  private abortExport(writer: FflateTransferArchiveWriter, error: unknown): void {
    this.dependencies.logger.exception("workspace_transfer.export_failed", error, {teamId: this.dependencies.teamId});
    writer.fail(error);
  }

  private failure(event: string, error: unknown, reply: FastifyReply): FastifyReply {
    if (error instanceof InvalidTransferRequestError) return reply.code(400).send({error: error.message});
    if (error instanceof InvalidTransferArchiveError) return reply.code(422).send({error: error.message});
    if (error instanceof TransferUploadTooLargeError) return reply.code(413).send({error: error.message});
    this.dependencies.logger.exception(`workspace_transfer.${event}`, error, {teamId: this.dependencies.teamId});
    return reply.code(500).send({error: "Import/Export ist fehlgeschlagen."});
  }
}

function categoriesOf(body: unknown): unknown {
  return typeof body === "object" && body !== null ? (body as {categories?: unknown}).categories : undefined;
}

function contentLength(request: FastifyRequest): number | null {
  const length = Number(request.headers["content-length"]);
  return Number.isSafeInteger(length) && length >= 0 ? length : null;
}

function exportFileName(now: Date): string {
  return `novooa-export-${now.toISOString().slice(0, 10)}.zip`;
}
