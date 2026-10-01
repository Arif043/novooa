import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply} from "fastify";
import {ErrorResponse} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type LocalRuntimeWorkspaceContext} from "../../../../shared/local/local-runtime-workspace-context.js";
import {
  TransferCategorySelection,
  transferCategories,
  type TransferCategory,
  type TransferCounts,
} from "../../domain/entities/transfer-category.js";
import {InvalidTransferArchiveError, InvalidTransferRequestError} from "../../domain/entities/transfer-errors.js";
import {type ExportWorkspace} from "../../domain/usecases/export-workspace.js";
import {type ImportWorkspace} from "../../domain/usecases/import-workspace.js";
import {type InspectWorkspaceImport} from "../../domain/usecases/inspect-workspace-import.js";
import {FflateTransferArchiveReader} from "../zip/fflate-transfer-archive-reader.js";
import {FflateTransferArchiveWriter} from "../zip/fflate-transfer-archive-writer.js";
import {type LocalTransferUploadStore, type StagedTransferUpload, TransferUploadTooLargeError} from "./local-transfer-upload-store.js";

export type WorkspaceTransferRoutesOptions = {
  exportWorkspace: ExportWorkspace;
  inspectImport: InspectWorkspaceImport;
  importWorkspace: ImportWorkspace;
  uploads: LocalTransferUploadStore;
  notifier: {publish(topic: string): void};
};

const realtimeTopics: Record<TransferCategory, readonly string[]> = {
  files: ["files", "folders"], data: [], knowledge: ["knowledge-notes"], tasks: ["tasks"],
};
const Category = Type.Enum(transferCategories);
const Selection = Type.Object({categories: Type.Array(Category, {minItems: 1})});
const Counts = Type.Partial(Type.Record(Category, Type.Integer()));
const Manifest = Type.Object({
  format: Type.String(), version: Type.Integer(), exportedAt: Type.String(), sourceTeamId: Type.String(),
  categories: Type.Array(Category), counts: Counts,
});
const ImportParams = Type.Object({importId: Type.String({minLength: 1, maxLength: 100})});
const failures = {400: ErrorResponse, 404: ErrorResponse, 413: ErrorResponse, 415: ErrorResponse, 422: ErrorResponse, 500: ErrorResponse};

export const workspaceTransferRoutes: FastifyPluginAsyncTypebox<WorkspaceTransferRoutesOptions> = async (app, options) => {
  app.post("/v1/transfer/export", {schema: {body: Selection}}, async (request, reply) => {
    const selection = TransferCategorySelection.of(request.body.categories);
    const writer = new FflateTransferArchiveWriter();
    const {teamId, logger} = request.workspace;
    void options.exportWorkspace.execute({teamId, selection, writer}).then(() => writer.finish(), (error: unknown) => {
      logger.exception("workspace_transfer.export_failed", error, {teamId});
      writer.fail(error);
    });
    return reply.type("application/zip")
      .header("content-disposition", `attachment; filename="${exportFileName(new Date())}"`).send(writer.output);
  });

  app.post("/v1/transfer/imports", {
    schema: {response: {...failures, 201: Type.Object({importId: Type.String(), manifest: Manifest})}},
  }, async (request, reply) => {
    if (request.headers["content-type"]?.split(";", 1)[0] !== "application/zip") {
      return reply.code(415).send({error: "Der Import erwartet eine ZIP-Datei (application/zip)."});
    }
    let upload: StagedTransferUpload | undefined;
    try {
      upload = await options.uploads.stage(request.raw, contentLength(request.headers["content-length"]));
      const manifest = await options.inspectImport.execute(new FflateTransferArchiveReader(upload.path));
      return reply.code(201).send({importId: upload.id, manifest});
    } catch (error) {
      await options.uploads.discard(upload);
      return failure(request.workspace, "import_upload_failed", error, reply);
    }
  });

  app.post("/v1/transfer/imports/:importId/apply", {
    schema: {params: ImportParams, body: Selection, response: {...failures, 200: Type.Object({imported: Counts})}},
  }, async (request, reply) => {
    const upload = await options.uploads.take(request.params.importId);
    if (upload === undefined) return reply.code(404).send({error: "Der Import ist abgelaufen. Bitte lade die Datei erneut hoch."});
    try {
      const imported = await options.importWorkspace.execute({teamId: request.workspace.teamId,
        selection: TransferCategorySelection.of(request.body.categories), reader: new FflateTransferArchiveReader(upload.path)});
      announce(options, request.workspace, imported);
      return {imported};
    } catch (error) {
      return failure(request.workspace, "import_failed", error, reply);
    } finally {
      await options.uploads.discard(upload);
    }
  });

  app.delete("/v1/transfer/imports/:importId", {schema: {params: ImportParams}}, async (request, reply) => {
    await options.uploads.discard(await options.uploads.take(request.params.importId));
    return reply.code(204).send();
  });
};

function announce(options: WorkspaceTransferRoutesOptions, workspace: LocalRuntimeWorkspaceContext, imported: TransferCounts): void {
  const categories = Object.keys(imported) as TransferCategory[];
  for (const topic of new Set(categories.flatMap((category) => realtimeTopics[category]))) options.notifier.publish(topic);
  workspace.logger.info("workspace_transfer.imported", {teamId: workspace.teamId, ...imported});
}

function failure(workspace: LocalRuntimeWorkspaceContext, event: string, error: unknown, reply: FastifyReply): FastifyReply {
  if (error instanceof InvalidTransferRequestError) return reply.code(400).send({error: error.message});
  if (error instanceof InvalidTransferArchiveError) return reply.code(422).send({error: error.message});
  if (error instanceof TransferUploadTooLargeError) return reply.code(413).send({error: error.message});
  workspace.logger.exception(`workspace_transfer.${event}`, error, {teamId: workspace.teamId});
  return reply.code(500).send({error: "Import/Export ist fehlgeschlagen."});
}

function contentLength(header: string | undefined): number | null {
  const length = Number(header);
  return Number.isSafeInteger(length) && length >= 0 ? length : null;
}

function exportFileName(now: Date): string {
  return `novooa-export-${now.toISOString().slice(0, 10)}.zip`;
}
