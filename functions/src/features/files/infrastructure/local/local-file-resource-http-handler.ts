import {randomUUID} from "node:crypto";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";
import {type LocalTeamFileStore} from "./local-team-file-store.js";
import {
  fileByIdSql,
  fileFromRow,
  filesSql,
  folderByIdSql,
  folderFromRow,
  foldersSql,
  insertFolderSql,
  type FileRow,
  type FolderRow,
  type VersionRow,
  versionFromRow,
  versionsSql,
} from "./local-file-resource-http-models.js";

export class LocalFileResourceHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly database: LocalSqlDatabase,
    private readonly fileStore: LocalTeamFileStore,
    private readonly teamId: string,
    private readonly userId: string,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    const path = pathFrom(request.url);
    if (request.method === "GET" && path === "/v1/files") return this.listFiles();
    if (request.method === "POST" && path === "/v1/files") return this.write(request.body, null);
    if (request.method === "GET" && path === "/v1/folders") return this.listFolders();
    if (request.method === "POST" && path === "/v1/folders") return this.createFolder(request.body);
    const content = versionContentFrom(path);
    if (request.method === "GET" && content !== null) return this.content(content);
    const fileId = versionFileIdFrom(path);
    if (request.method === "GET" && fileId !== null) return this.listVersions(fileId);
    if (request.method === "POST" && fileId !== null) return this.write(request.body, fileId);
    return null;
  }

  private async listFiles(): Promise<LocalRuntimeResponse> {
    const rows = await this.database.all<FileRow>(filesSql(), [this.teamId]);
    return {body: {items: rows.map(fileFromRow)}, statusCode: 200};
  }

  private async listFolders(): Promise<LocalRuntimeResponse> {
    const rows = await this.database.all<FolderRow>(foldersSql(), [this.teamId]);
    return {body: {items: rows.map(folderFromRow)}, statusCode: 200};
  }

  private async createFolder(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const input = folderFromRequest(body);
      await ensureFolder(this.database, this.teamId, input.parentFolderId);
      const id = randomUUID();
      await this.database.run(insertFolderSql(), [id, this.teamId, this.userId, input.name, input.parentFolderId]);
      return this.folderById(id, 201);
    } catch (error) {
      return invalidResponse(error);
    }
  }

  private async write(body: unknown, targetFileId: string | null): Promise<LocalRuntimeResponse> {
    try {
      const input = fileFromRequest(body);
      if (targetFileId === null) await ensureFolder(this.database, this.teamId, input.folderId);
      const written = await this.fileStore.writeTeamFile({
        teamId: this.teamId, fileName: input.name, contentType: input.contentType,
        content: Buffer.from(input.contentBase64, "base64"), folderId: input.folderId, targetFileId,
      });
      return this.fileById(written.fileId, targetFileId === null ? 201 : 200);
    } catch (error) {
      return invalidResponse(error);
    }
  }

  private async listVersions(fileId: string): Promise<LocalRuntimeResponse> {
    const rows = await this.database.all<VersionRow>(versionsSql(), [this.teamId, fileId]);
    return {body: {items: rows.map(versionFromRow)}, statusCode: 200};
  }

  private async content(input: {fileId: string; versionId: string}): Promise<LocalRuntimeResponse> {
    try {
      const content = await this.fileStore.readTeamFileContent(this.teamId, input.fileId, input.versionId);
      return {body: {contentBase64: Buffer.from(content.content).toString("base64")}, statusCode: 200};
    } catch {
      return {body: {error: "Dateiversion nicht gefunden."}, statusCode: 404};
    }
  }

  private async fileById(id: string, statusCode: number): Promise<LocalRuntimeResponse> {
    const row = await this.database.get<FileRow>(fileByIdSql(), [this.teamId, id]);
    return row === null ? {body: {error: "Datei nicht gefunden."}, statusCode: 404} : {body: fileFromRow(row), statusCode};
  }

  private async folderById(id: string, statusCode: number): Promise<LocalRuntimeResponse> {
    const row = await this.database.get<FolderRow>(folderByIdSql(), [this.teamId, id]);
    return row === null ? {body: {error: "Verzeichnis nicht gefunden."}, statusCode: 404} : {body: folderFromRow(row), statusCode};
  }
}

function fileFromRequest(value: unknown): FileInput {
  const input = recordFrom(value);
  const name = stringFrom(input.name, "name");
  if (name.includes("/") || name.includes("\\") || name === "." || name === "..") throw new LocalFileRequestError("name darf keinen Pfad enthalten.");
  const contentBase64 = stringFrom(input.contentBase64, "contentBase64");
  if (!/^[A-Za-z0-9+/]*={0,2}$/.test(contentBase64)) throw new LocalFileRequestError("contentBase64 ist ungültig.");
  return {name, contentBase64, contentType: optionalString(input.contentType) || "application/octet-stream", folderId: nullableString(input.folderId)};
}

function folderFromRequest(value: unknown): {name: string; parentFolderId: string | null} {
  const input = recordFrom(value);
  const name = stringFrom(input.name, "name").trim();
  if (!name) throw new LocalFileRequestError("name muss ein nicht leerer String sein.");
  return {name, parentFolderId: nullableString(input.parentFolderId)};
}

async function ensureFolder(database: LocalSqlDatabase, teamId: string, folderId: string | null): Promise<void> {
  if (folderId === null) return;
  const folder = await database.get<SqlRow>("SELECT id FROM file_folders WHERE team_id = ? AND id = ?", [teamId, folderId]);
  if (folder === null) throw new LocalFileRequestError("Das Verzeichnis existiert nicht.");
}

function pathFrom(url: string | undefined): string {
  return new URL(url ?? "/", "http://local-runtime").pathname;
}

function versionFileIdFrom(path: string): string | null {
  const match = /^\/v1\/files\/([^/]+)\/versions$/.exec(path);
  return match?.[1] ? decodeURIComponent(match[1]) : null;
}

function versionContentFrom(path: string): {fileId: string; versionId: string} | null {
  const match = /^\/v1\/files\/([^/]+)\/versions\/([^/]+)\/content$/.exec(path);
  return match?.[1] && match[2] ? {fileId: decodeURIComponent(match[1]), versionId: decodeURIComponent(match[2])} : null;
}

function recordFrom(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new LocalFileRequestError("Die lokale Datei erwartet ein Objekt.");
}

function stringFrom(value: unknown, name: string): string {
  if (typeof value === "string") return value;
  throw new LocalFileRequestError(`${name} muss ein String sein.`);
}

function optionalString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function nullableString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

function invalidResponse(error: unknown): LocalRuntimeResponse {
  if (error instanceof LocalFileRequestError) return {body: {error: error.message}, statusCode: 400};
  throw error;
}

type FileInput = {contentBase64: string; contentType: string; folderId: string | null; name: string};

class LocalFileRequestError extends Error {}
