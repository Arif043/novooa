import {and, desc, eq, getTableColumns, sql} from "drizzle-orm";
import {type FastifyInstance, type FastifyReply} from "fastify";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {fileFolders, files, fileVersions} from "../../../../db/schema.js";
import {type LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {fileFromRow, folderFromRow, versionFromRow, } from "./local-file-resource-http-models.js";
import {type LocalTeamFileStore} from "./local-team-file-store.js";
export class LocalFileResourceHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalFileResourceHttpHandler): void {
    http.get("/v1/files", (request, reply) => current().listFiles(reply));
    http.post("/v1/files", (request, reply) => current().write(request.body, null, reply));
    http.get("/v1/folders", (request, reply) => current().listFolders(reply));
    http.post("/v1/folders", (request, reply) => current().createFolder(request.body, reply));
    http.get<{Params: {fileId: string; versionId: string}}>("/v1/files/:fileId/versions/:versionId/content", (request, reply) => current().content(request.params, reply));
    http.get<{Params: {fileId: string}}>("/v1/files/:fileId/versions", (request, reply) => current().listVersions(request.params.fileId, reply));
    http.post<{Params: {fileId: string}}>("/v1/files/:fileId/versions", (request, reply) => current().write(request.body, request.params.fileId, reply));
  }
  constructor(private readonly database: RuntimeExecutor, private readonly fileStore: LocalTeamFileStore, private readonly teamId: string, private readonly userId: string, private readonly notifier: LocalRuntimeRealtimeNotifier) { }
  private async listFiles(reply: FastifyReply): Promise<FastifyReply> {
    const rows = await fileQuery(this.database).where(eq(files.team_id, this.teamId)).orderBy(desc(files.updated_at));
    return reply.code(200).send({ items: rows.map(fileFromRow) });
  }
  private async listFolders(reply: FastifyReply): Promise<FastifyReply> {
    const rows = await this.database.select({id: fileFolders.id, team_id: fileFolders.team_id, owner_uid: fileFolders.owner_uid, name: fileFolders.name, parent_folder_id: fileFolders.parent_folder_id, created_at: fileFolders.created_at, updated_at: fileFolders.updated_at}).from(fileFolders).where(eq(fileFolders.team_id, this.teamId)).orderBy(sql`${fileFolders.name} COLLATE NOCASE`);
    return reply.code(200).send({ items: rows.map(folderFromRow) });
  }
  private async createFolder(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const input = folderFromRequest(body);
      await ensureFolder(this.database, this.teamId, input.parentFolderId);
      const id = randomUUID();
      await this.database.insert(fileFolders).values({id: id, team_id: this.teamId, owner_uid: this.userId, name: input.name, parent_folder_id: input.parentFolderId});
      this.notifier.publish("folders");
      return this.folderById(id, 201, reply);
    }
    catch (error) {
      return invalidResponse(error, reply);
    }
  }
  private async write(body: unknown, targetFileId: string | null, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const input = fileFromRequest(body);
      if (targetFileId === null)
        await ensureFolder(this.database, this.teamId, input.folderId);
      const written = await this.fileStore.writeTeamFile({
        teamId: this.teamId, fileName: input.name, contentType: input.contentType,
        content: Buffer.from(input.contentBase64, "base64"), folderId: input.folderId, targetFileId,
      });
      this.notifier.publish("files");
      this.notifier.publish(`file-versions:${written.fileId}`);
      return this.fileById(written.fileId, targetFileId === null ? 201 : 200, reply);
    }
    catch (error) {
      return invalidResponse(error, reply);
    }
  }
  private async listVersions(fileId: string, reply: FastifyReply): Promise<FastifyReply> {
    const rows = await this.database.select({id: fileVersions.id, file_id: fileVersions.file_id, team_id: fileVersions.team_id, created_by_uid: fileVersions.created_by_uid, display_name: fileVersions.display_name, storage_path: fileVersions.storage_path, content_type: fileVersions.content_type, size_bytes: fileVersions.size_bytes, created_at: fileVersions.created_at}).from(fileVersions).where(and(eq(fileVersions.team_id, this.teamId), eq(fileVersions.file_id, fileId))).orderBy(desc(fileVersions.created_at));
    return reply.code(200).send({ items: rows.map(versionFromRow) });
  }
  private async content(input: {
    fileId: string;
    versionId: string;
  }, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const content = await this.fileStore.readTeamFileContent(this.teamId, input.fileId, input.versionId);
      return reply.code(200).send({ contentBase64: Buffer.from(content.content).toString("base64") });
    }
    catch {
      return reply.code(404).send({ error: "Dateiversion nicht gefunden." });
    }
  }
  private async fileById(id: string, statusCode: number, reply: FastifyReply): Promise<FastifyReply> {
    const row = await fileQuery(this.database).where(and(eq(files.team_id, this.teamId), eq(files.id, id))).get();
    return row === undefined ? reply.code(404).send({ error: "Datei nicht gefunden." }) : reply.code(statusCode).send(fileFromRow(row));
  }
  private async folderById(id: string, statusCode: number, reply: FastifyReply): Promise<FastifyReply> {
    const row = (await this.database.select({id: fileFolders.id, team_id: fileFolders.team_id, owner_uid: fileFolders.owner_uid, name: fileFolders.name, parent_folder_id: fileFolders.parent_folder_id, created_at: fileFolders.created_at, updated_at: fileFolders.updated_at}).from(fileFolders).where(and(eq(fileFolders.team_id, this.teamId), eq(fileFolders.id, id))).get()) ?? null;
    return row === null ? reply.code(404).send({ error: "Verzeichnis nicht gefunden." }) : reply.code(statusCode).send(folderFromRow(row));
  }
}
function fileQuery(database: RuntimeExecutor) {
  return database.select({...getTableColumns(files), current_version_created_at: fileVersions.created_at})
    .from(files).innerJoin(fileVersions, eq(fileVersions.id, files.current_version_id));
}

function fileFromRequest(value: unknown): FileInput {
  const input = recordFrom(value);
  const name = stringFrom(input.name, "name");
  if (name.includes("/") || name.includes("\\") || name === "." || name === "..")
    throw new LocalFileRequestError("name darf keinen Pfad enthalten.");
  const contentBase64 = stringFrom(input.contentBase64, "contentBase64");
  if (!/^[A-Za-z0-9+/]*={0,2}$/.test(contentBase64))
    throw new LocalFileRequestError("contentBase64 ist ungültig.");
  return { name, contentBase64, contentType: optionalString(input.contentType) || "application/octet-stream", folderId: nullableString(input.folderId) };
}
function folderFromRequest(value: unknown): {
  name: string;
  parentFolderId: string | null;
} {
  const input = recordFrom(value);
  const name = stringFrom(input.name, "name").trim();
  if (!name)
    throw new LocalFileRequestError("name muss ein nicht leerer String sein.");
  return { name, parentFolderId: nullableString(input.parentFolderId) };
}
async function ensureFolder(database: RuntimeExecutor, teamId: string, folderId: string | null): Promise<void> {
  if (folderId === null)
    return;
  const folder = (await database.select({id: fileFolders.id}).from(fileFolders).where(and(eq(fileFolders.team_id, teamId), eq(fileFolders.id, folderId))).get()) ?? null;
  if (folder === null)
    throw new LocalFileRequestError("Das Verzeichnis existiert nicht.");
}
function recordFrom(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value))
    return value as Record<string, unknown>;
  throw new LocalFileRequestError("Die lokale Datei erwartet ein Objekt.");
}
function stringFrom(value: unknown, name: string): string {
  if (typeof value === "string")
    return value;
  throw new LocalFileRequestError(`${name} muss ein String sein.`);
}
function optionalString(value: unknown): string {
  return typeof value === "string" ? value : "";
}
function nullableString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}
function invalidResponse(error: unknown, reply: FastifyReply): FastifyReply {
  if (error instanceof LocalFileRequestError)
    return reply.code(400).send({ error: error.message });
  throw error;
}
type FileInput = {
  contentBase64: string;
  contentType: string;
  folderId: string | null;
  name: string;
};
class LocalFileRequestError extends Error {
}
