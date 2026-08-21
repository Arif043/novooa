import {randomUUID} from "node:crypto";
import {mkdir, readFile, writeFile} from "node:fs/promises";
import path from "node:path";
import {storagePathFor} from "../../domain/entities/file-storage-path.js";
import {type NodeAttachment} from "../../../task_execution/domain/entities/attachments.js";
import {
  type TeamFileContent,
  type TeamFileContentReader,
} from "../../domain/repositories/team-file-content-reader.js";
import {
  contentSizeBytes,
  type FileContent,
  type StoredTeamFile,
  type TeamFileStore,
  type WriteTeamFileInput,
  type WrittenFile,
} from "../../domain/repositories/team-file-store.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";

type ExistingFile = {
  fileId: string;
  ownerUid: string;
  folderId: string | null;
};

type FileRow = SqlRow & {
  id: string;
  owner_uid: string;
  folder_id: string | null;
};

type StoredFileRow = FileRow & {
  current_version_id: string;
  display_name: string;
  content_type: string;
  size_bytes: number;
  storage_path: string;
};

type StoredFileVersionRow = SqlRow & {
  display_name: string;
  content_type: string;
  size_bytes: number;
  storage_path: string;
};

export class LocalTeamFileStore implements TeamFileStore, TeamFileContentReader {
  constructor(
    private readonly database: LocalSqlDatabase,
    private readonly rootDirectory: string,
  ) {}

  async writeTeamFile(input: WriteTeamFileInput): Promise<WrittenFile> {
    const file = await this.writtenFileFrom(input);
    await writeLocalFile(this.rootDirectory, file.storagePath, input.content);
    await this.writeMetadata(input.teamId, file);
    return file;
  }

  async readTextFile(teamId: string, file: NodeAttachment): Promise<string> {
    ensureTeamFile(file, teamId);
    return readFile(localPath(this.rootDirectory, file.storagePath), "utf8");
  }

  async loadTeamFile(
    teamId: string,
    fileId: string,
  ): Promise<StoredTeamFile> {
    const row = await this.database.get<StoredFileRow>(loadFileSql(), [
      teamId,
      fileId,
    ]);
    if (row === null) throw new Error(`Datei nicht gefunden: ${fileId}`);
    return {
      fileId: row.id,
      versionId: row.current_version_id,
      storagePath: row.storage_path,
      displayName: row.display_name,
      contentType: row.content_type,
      sizeBytes: row.size_bytes,
    };
  }

  async readTeamFileContent(
    teamId: string,
    fileId: string,
    versionId: string,
  ): Promise<TeamFileContent> {
    const file = await this.database.get<StoredFileVersionRow>(
      loadFileVersionSql(),
      [teamId, fileId, versionId],
    );
    if (file === null) throw new Error(`Dateiversion nicht gefunden: ${versionId}`);
    return {
      content: await readFile(localPath(this.rootDirectory, file.storage_path)),
      displayName: file.display_name,
      contentType: file.content_type,
      sizeBytes: file.size_bytes,
    };
  }

  private async writtenFileFrom(input: WriteTeamFileInput): Promise<WrittenFile> {
    if (input.targetFileId !== null) return this.versionedFileFrom(input);
    const existingFile = await this.existingFileByNameFor(input);
    if (existingFile !== null) return versionFromExisting(input, existingFile);
    return newFileFrom(input);
  }

  private async versionedFileFrom(input: WriteTeamFileInput): Promise<WrittenFile> {
    const existingFile = await this.existingFileFor(input);
    return versionFromExisting(input, existingFile);
  }

  private async existingFileFor(input: WriteTeamFileInput): Promise<ExistingFile> {
    if (input.targetFileId === null) throw new Error("Datei-ID fehlt.");
    const row = await this.database.get<FileRow>(
      "SELECT id, owner_uid, folder_id FROM files WHERE team_id = ? AND id = ?",
      [input.teamId, input.targetFileId],
    );
    if (row === null) throw new Error(`Datei nicht gefunden: ${input.targetFileId}`);
    return existingFileFrom(row);
  }

  private async existingFileByNameFor(
    input: WriteTeamFileInput,
  ): Promise<ExistingFile | null> {
    const row = await this.database.get<FileRow>(findFileByNameSql(), [
      input.teamId,
      input.fileName,
    ]);
    return row === null ? null : existingFileFrom(row);
  }

  private async writeMetadata(teamId: string, file: WrittenFile) {
    await this.database.transaction(async () => {
      await upsertFile(this.database, teamId, file);
      await insertVersion(this.database, teamId, file);
    });
  }
}

function newFileFrom(input: WriteTeamFileInput): WrittenFile {
  const fileId = randomUUID();
  const versionId = randomUUID();
  return writtenFile(input, fileId, versionId, null, "system", true);
}

function versionFromExisting(
  input: WriteTeamFileInput,
  existingFile: ExistingFile,
): WrittenFile {
  return writtenFile(
    input,
    existingFile.fileId,
    randomUUID(),
    existingFile.folderId,
    existingFile.ownerUid,
    false,
  );
}

function writtenFile(
  input: WriteTeamFileInput,
  fileId: string,
  versionId: string,
  folderId: string | null,
  ownerUid: string,
  isNewFile: boolean,
): WrittenFile {
  return {
    fileId,
    versionId,
    displayName: input.fileName,
    contentType: input.contentType,
    sizeBytes: contentSizeBytes(input.content),
    folderId,
    ownerUid,
    isNewFile,
    storagePath: storagePathFor(input.teamId, fileId, versionId, input.fileName),
  };
}

async function upsertFile(
  database: LocalSqlDatabase,
  teamId: string,
  file: WrittenFile,
) {
  await database.run(upsertFileSql(), [
    file.fileId,
    teamId,
    file.ownerUid,
    file.displayName,
    file.folderId,
    file.versionId,
    file.contentType,
    file.sizeBytes,
    file.storagePath,
  ]);
}

async function insertVersion(
  database: LocalSqlDatabase,
  teamId: string,
  file: WrittenFile,
) {
  await database.run(insertVersionSql(), [
    file.versionId,
    teamId,
    file.fileId,
    "system",
    file.displayName,
    file.storagePath,
    file.contentType,
    file.sizeBytes,
  ]);
}

async function writeLocalFile(
  rootDirectory: string,
  storagePath: string,
  content: FileContent,
) {
  const destination = localPath(rootDirectory, storagePath);
  await mkdir(path.dirname(destination), {recursive: true});
  await writeFile(destination, content);
}

function localPath(rootDirectory: string, storagePath: string): string {
  return path.join(rootDirectory, storagePath);
}

function ensureTeamFile(file: NodeAttachment, teamId: string): void {
  if (file.storagePath.startsWith(`teams/${teamId}/files/`)) return;
  throw new Error("Datei lesen: Die Datei gehört nicht zum aktuellen Team.");
}

function existingFileFrom(row: FileRow): ExistingFile {
  return {fileId: row.id, ownerUid: row.owner_uid, folderId: row.folder_id};
}

function findFileByNameSql() {
  return `SELECT id, owner_uid, folder_id FROM files
    WHERE team_id = ? AND display_name = ? AND folder_id IS NULL LIMIT 1`;
}

function loadFileSql() {
  return `SELECT id, owner_uid, folder_id, current_version_id, display_name,
    content_type, size_bytes, storage_path FROM files
    WHERE team_id = ? AND id = ?`;
}

function loadFileVersionSql() {
  return `SELECT display_name, content_type, size_bytes, storage_path
    FROM file_versions WHERE team_id = ? AND file_id = ? AND id = ?`;
}

function upsertFileSql() {
  return `INSERT INTO files(id, team_id, owner_uid, display_name, folder_id,
    current_version_id, content_type, size_bytes, storage_path)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET current_version_id = excluded.current_version_id,
    content_type = excluded.content_type, size_bytes = excluded.size_bytes,
    storage_path = excluded.storage_path, updated_at = CURRENT_TIMESTAMP`;
}

function insertVersionSql() {
  return `INSERT INTO file_versions(id, team_id, file_id, created_by_uid,
    display_name, storage_path, content_type, size_bytes)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)`;
}
