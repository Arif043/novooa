import {type FastifyPluginAsyncTypebox, type Static, Type} from "@fastify/type-provider-typebox";
import {and, desc, eq, sql} from "drizzle-orm";
import {type FastifyReply} from "fastify";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {fileFolders, files, fileVersions} from "../../../../db/schema.js";
import {ErrorResponse, ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type LocalRuntimeWorkspaceContext} from "../../../../shared/local/local-runtime-workspace-context.js";
import {
  FileParams, FileUpload, FileVersionDto, FolderDto, NewFolder, TeamFileDto, VersionParams,
  fileFromRow, folderFromRow, versionFromRow,
} from "./local-file-schemas.js";
import {currentFilesQuery, fileVersionsQuery} from "./local-file-queries.js";
import {type LocalTeamFileStore} from "./local-team-file-store.js";

export type FileResourceRoutesOptions = {
  database: RuntimeExecutor;
  fileStore: Pick<LocalTeamFileStore, "writeTeamFile" | "readTeamFileContent" | "deleteTeamFile">;
  notifier: {publish(topic: string): void};
};

const folderColumns = {
  id: fileFolders.id, team_id: fileFolders.team_id, owner_uid: fileFolders.owner_uid, name: fileFolders.name,
  parent_folder_id: fileFolders.parent_folder_id, created_at: fileFolders.created_at, updated_at: fileFolders.updated_at,
};
const fileResponses = {200: TeamFileDto, 201: TeamFileDto, 400: ErrorResponse, 404: ErrorResponse};

export const fileResourceRoutes: FastifyPluginAsyncTypebox<FileResourceRoutesOptions> = async (app, options) => {
  const {database, fileStore, notifier} = options;

  app.get("/v1/files", {schema: {response: {200: ItemsOf(TeamFileDto)}}}, async (request) => {
    const rows = await currentFilesQuery(database).where(eq(files.team_id, request.workspace.teamId)).orderBy(desc(files.updated_at));
    return {items: rows.map(fileFromRow)};
  });

  app.get("/v1/folders", {schema: {response: {200: ItemsOf(FolderDto)}}}, async (request) => {
    const rows = await database.select(folderColumns).from(fileFolders)
      .where(eq(fileFolders.team_id, request.workspace.teamId)).orderBy(sql`${fileFolders.name} COLLATE NOCASE`);
    return {items: rows.map(folderFromRow)};
  });

  app.post("/v1/folders", {
    schema: {body: NewFolder, response: {201: FolderDto, 400: ErrorResponse, 404: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId, userId} = request.workspace;
    const parentFolderId = request.body.parentFolderId || null;
    if (!await folderExists(database, teamId, parentFolderId)) return reply.code(400).send(missingFolder);
    const id = randomUUID();
    await database.insert(fileFolders).values({id, team_id: teamId, owner_uid: userId, name: request.body.name.trim(),
      parent_folder_id: parentFolderId});
    notifier.publish("folders");
    const row = await database.select(folderColumns).from(fileFolders)
      .where(and(eq(fileFolders.team_id, teamId), eq(fileFolders.id, id))).get();
    return row === undefined ? reply.code(404).send({error: "Verzeichnis nicht gefunden."}) : reply.code(201).send(folderFromRow(row));
  });

  app.post("/v1/files", {schema: {body: FileUpload, response: fileResponses}}, async (request, reply) =>
    writeFile(options, request.workspace, request.body, null, reply));

  app.post("/v1/files/:fileId/versions", {schema: {params: FileParams, body: FileUpload, response: fileResponses}},
    async (request, reply) => writeFile(options, request.workspace, request.body, request.params.fileId, reply));

  app.delete("/v1/files/:fileId", {
    schema: {params: FileParams, response: {204: Type.Null(), 404: ErrorResponse}},
  }, async (request, reply) => {
    const deleted = await fileStore.deleteTeamFile(request.workspace.teamId, request.params.fileId);
    if (!deleted) return reply.code(404).send({error: "Datei nicht gefunden."});
    notifier.publish("files");
    return reply.code(204).send(null);
  });

  app.get("/v1/files/:fileId/versions", {schema: {params: FileParams, response: {200: ItemsOf(FileVersionDto)}}},
    async (request) => {
      const rows = await fileVersionsQuery(database)
        .where(and(eq(files.team_id, request.workspace.teamId), eq(fileVersions.file_id, request.params.fileId)))
        .orderBy(desc(fileVersions.created_at));
      return {items: rows.map(versionFromRow)};
    });

  app.get("/v1/files/:fileId/versions/:versionId/content", {
    schema: {params: VersionParams, response: {200: Type.Object({contentBase64: Type.String()}), 404: ErrorResponse}},
  }, async (request, reply) => {
    const {fileId, versionId} = request.params;
    try {
      const content = await fileStore.readTeamFileContent(request.workspace.teamId, fileId, versionId);
      return {contentBase64: Buffer.from(content.content).toString("base64")};
    } catch {
      return reply.code(404).send({error: "Dateiversion nicht gefunden."});
    }
  });
};

const missingFolder = {error: "Das Verzeichnis existiert nicht."};

async function writeFile(
  {database, fileStore, notifier}: FileResourceRoutesOptions, workspace: LocalRuntimeWorkspaceContext,
  body: Static<typeof FileUpload>, targetFileId: string | null, reply: FastifyReply,
): Promise<FastifyReply> {
  const folderId = body.folderId || null;
  if (targetFileId === null && !await folderExists(database, workspace.teamId, folderId)) {
    return reply.code(400).send(missingFolder);
  }
  const written = await fileStore.writeTeamFile({
    teamId: workspace.teamId, fileName: body.name, contentType: body.contentType || "application/octet-stream",
    content: Buffer.from(body.contentBase64, "base64"), folderId, targetFileId,
  });
  notifier.publish("files");
  notifier.publish(`file-versions:${written.fileId}`);
  const row = await currentFilesQuery(database).where(and(eq(files.team_id, workspace.teamId), eq(files.id, written.fileId))).get();
  return row === undefined
    ? reply.code(404).send({error: "Datei nicht gefunden."})
    : reply.code(targetFileId === null ? 201 : 200).send(fileFromRow(row));
}

async function folderExists(database: RuntimeExecutor, teamId: string, folderId: string | null): Promise<boolean> {
  if (folderId === null) return true;
  const folder = await database.select({id: fileFolders.id}).from(fileFolders)
    .where(and(eq(fileFolders.team_id, teamId), eq(fileFolders.id, folderId))).get();
  return folder !== undefined;
}
