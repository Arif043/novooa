import {and, eq, inArray, isNull, sql} from "drizzle-orm";
import {randomUUID} from "node:crypto";
import {readFile, rm} from "node:fs/promises";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {files, fileVersions, type Files} from "../../../../db/schema.js";
import {type NodeAttachment} from "../../../task_execution/domain/entities/attachments.js";
import {storagePathFor} from "../../domain/entities/file-storage-path.js";
import {
  DEFAULT_FILE_VERSION_LIMIT,
  versionsToRotateOut,
} from "../../domain/entities/file-version-rotation.js";
import {localFilePath, writeLocalFile} from "./local-file-path.js";
import {
  type TeamFileContent,
  type TeamFileContentReader,
} from "../../domain/repositories/team-file-content-reader.js";
import {
  contentSizeBytes,
  type StoredTeamFile,
  type TeamFileStore,
  type WriteTeamFileInput,
  type WrittenFile,
} from "../../domain/repositories/team-file-store.js";

type ExistingFile = {
  fileId: string;
  ownerUid: string;
  folderId: string | null;
};

type FileRow = Pick<Files, "id" | "owner_uid" | "folder_id">;

export class LocalTeamFileStore implements TeamFileStore, TeamFileContentReader {
  constructor(
    private readonly database: RuntimeExecutor,
    private readonly rootDirectory: string,
    private readonly versionLimit: number = DEFAULT_FILE_VERSION_LIMIT,
  ) {}

  async writeTeamFile(input: WriteTeamFileInput): Promise<WrittenFile> {
    const file = await this.writtenFileFrom(input);
    await writeLocalFile(this.rootDirectory, file.storagePath, input.content);
    await this.writeMetadata(input.teamId, file);
    await this.rotateVersions(input.teamId, file);
    return file;
  }

  async readTextFile(teamId: string, file: NodeAttachment): Promise<string> {
    ensureTeamFile(file, teamId);
    return readFile(localFilePath(this.rootDirectory, file.storagePath), "utf8");
  }

  async loadTeamFile(
    teamId: string,
    fileId: string,
  ): Promise<StoredTeamFile> {
    const row = (await this.database.select({id: files.id, owner_uid: files.owner_uid, folder_id: files.folder_id, current_version_id: files.current_version_id, display_name: files.display_name, content_type: files.content_type, size_bytes: files.size_bytes, storage_path: files.storage_path}).from(files).where(and(eq(files.team_id, teamId), eq(files.id, fileId))).get()) ?? null;
    if (row === null || row.current_version_id === null) throw new Error(`Datei nicht gefunden: ${fileId}`);
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
    const file = (await this.database.select({display_name: fileVersions.display_name, content_type: fileVersions.content_type, size_bytes: fileVersions.size_bytes, storage_path: fileVersions.storage_path}).from(fileVersions).where(and(eq(fileVersions.team_id, teamId), eq(fileVersions.file_id, fileId), eq(fileVersions.id, versionId))).get()) ?? null;
    if (file === null) throw new Error(`Dateiversion nicht gefunden: ${versionId}`);
    return {
      content: await readFile(localFilePath(this.rootDirectory, file.storage_path)),
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
    const row = (await this.database.select({id: files.id, owner_uid: files.owner_uid, folder_id: files.folder_id}).from(files).where(and(eq(files.team_id, input.teamId), eq(files.id, input.targetFileId))).get()) ?? null;
    if (row === null) throw new Error(`Datei nicht gefunden: ${input.targetFileId}`);
    return existingFileFrom(row);
  }

  private async existingFileByNameFor(
    input: WriteTeamFileInput,
  ): Promise<ExistingFile | null> {
    const row = await this.database.select({id: files.id, owner_uid: files.owner_uid, folder_id: files.folder_id})
      .from(files).where(and(eq(files.team_id, input.teamId), eq(files.display_name, input.fileName), isNull(files.folder_id)))
      .limit(1).get();
    return row ? existingFileFrom(row) : null;
  }

  private async rotateVersions(teamId: string, file: WrittenFile) {
    const rows = await this.database.select({
      id: fileVersions.id,
      storage_path: fileVersions.storage_path,
      created_at: fileVersions.created_at,
    }).from(fileVersions)
      .where(and(eq(fileVersions.team_id, teamId), eq(fileVersions.file_id, file.fileId)))
      // created_at hat Sekundenauflösung; rowid-Reihenfolge entscheidet bei Gleichstand.
      .orderBy(sql`rowid DESC`);
    const stale = versionsToRotateOut(
      rows.map((row) => ({...row, createdAt: Date.parse(`${row.created_at.replace(" ", "T")}Z`)})),
      this.versionLimit,
      file.versionId,
    );
    if (stale.length === 0) return;
    await this.database.delete(fileVersions).where(and(
      eq(fileVersions.team_id, teamId),
      inArray(fileVersions.id, stale.map((version) => version.id)),
    ));
    await Promise.all(stale.map((version) =>
      rm(localFilePath(this.rootDirectory, version.storage_path), {force: true})));
  }

  private async writeMetadata(teamId: string, file: WrittenFile) {
    await this.database.transaction(async (tx) => {
      await upsertFile(tx, teamId, file);
      await insertVersion(tx, teamId, file);
    });
  }
}

function newFileFrom(input: WriteTeamFileInput): WrittenFile {
  const fileId = randomUUID();
  const versionId = randomUUID();
  return writtenFile(input, fileId, versionId, input.folderId ?? null, "system", true);
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
  database: RuntimeExecutor,
  teamId: string,
  file: WrittenFile,
) {
  await database.insert(files).values({id: file.fileId, team_id: teamId, owner_uid: file.ownerUid, display_name: file.displayName, folder_id: file.folderId, current_version_id: file.versionId, content_type: file.contentType, size_bytes: file.sizeBytes, storage_path: file.storagePath}).onConflictDoUpdate({target: files.id, set: {current_version_id: file.versionId, content_type: file.contentType, size_bytes: file.sizeBytes, storage_path: file.storagePath, updated_at: sql`CURRENT_TIMESTAMP`}});
}

async function insertVersion(
  database: RuntimeExecutor,
  teamId: string,
  file: WrittenFile,
) {
  await database.insert(fileVersions).values({id: file.versionId, team_id: teamId, file_id: file.fileId, created_by_uid: "system", display_name: file.displayName, storage_path: file.storagePath, content_type: file.contentType, size_bytes: file.sizeBytes});
}

function ensureTeamFile(file: NodeAttachment, teamId: string): void {
  if (file.storagePath.startsWith(`teams/${teamId}/files/`)) return;
  throw new Error("Datei lesen: Die Datei gehört nicht zum aktuellen Team.");
}

function existingFileFrom(row: FileRow): ExistingFile {
  return {fileId: row.id, ownerUid: row.owner_uid, folderId: row.folder_id};
}
