import {and, eq} from "drizzle-orm";
import {access, rm} from "node:fs/promises";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {fileFolders, files, fileVersions} from "../../../../db/schema.js";
import {localFilePath, writeLocalFile} from "../../../files/infrastructure/local/local-file-path.js";
import {InvalidTransferArchiveError} from "../../domain/entities/transfer-errors.js";
import {type TransferTeamMapping} from "../../domain/entities/transfer-team-mapping.js";
import {transferBlobEntry, type TransferArchiveReader} from "../../domain/repositories/transfer-archive.js";
import {
  filesTransferPayload,
  parentsFirst,
  type FileDto,
  type FilesTransferPayload,
  type FolderDto,
  type VersionDto,
} from "./files-transfer-payload.js";
import {sectionPayload, type SqliteTransferSectionImporter, type StagedSectionImport} from "./sqlite-transfer-section-importer.js";

export class SqliteFilesTransferImporter implements SqliteTransferSectionImporter {
  readonly category = "files" as const;

  constructor(private readonly rootDirectory: string) {}

  async stage(reader: TransferArchiveReader, mapping: TransferTeamMapping): Promise<StagedSectionImport> {
    const payload = await sectionPayload(reader, "files", filesTransferPayload);
    const created = await this.copyBlobs(reader, payload.versions, mapping);
    return {
      count: payload.files.length,
      commit: (executor) => commitFiles(executor, payload, mapping),
      rollback: () => removeAll(created),
    };
  }

  /** Liefert die neu angelegten Pfade; bestehende Dateien werden nur überschrieben. */
  private async copyBlobs(
    reader: TransferArchiveReader, versions: readonly VersionDto[], mapping: TransferTeamMapping,
  ): Promise<string[]> {
    const targets = new Map(versions.map((version) => [
      transferBlobEntry(version.storagePath), mapping.storagePath(version.storagePath),
    ]));
    const created: string[] = [];
    try {
      await reader.forEachBlob(new Set(targets.keys()), async (name, content) => {
        await this.writeBlob(targets.get(name) as string, content, created);
        targets.delete(name);
      });
      if (targets.size > 0) throw new InvalidTransferArchiveError("Im Export fehlen Dateiinhalte.");
      return created;
    } catch (error) {
      await removeAll(created);
      throw error;
    }
  }

  private async writeBlob(storagePath: string, content: Uint8Array, created: string[]): Promise<void> {
    const absolutePath = localFilePath(this.rootDirectory, storagePath);
    const existed = await access(absolutePath).then(() => true, () => false);
    await writeLocalFile(this.rootDirectory, storagePath, content);
    if (!existed) created.push(absolutePath);
  }
}

async function commitFiles(
  executor: RuntimeExecutor, payload: FilesTransferPayload, mapping: TransferTeamMapping,
): Promise<void> {
  const teamId = mapping.targetTeamId;
  for (const folder of parentsFirst(payload.folders)) await upsertFolder(executor, teamId, folder);
  for (const file of payload.files) await upsertFile(executor, teamId, file);
  for (const version of payload.versions) {
    await upsertVersion(executor, teamId, version, mapping.storagePath(version.storagePath));
  }
  for (const file of payload.files) {
    await executor.update(files).set({current_version_id: file.currentVersionId})
      .where(and(eq(files.id, file.id), eq(files.team_id, teamId)));
  }
}

async function upsertFolder(executor: RuntimeExecutor, teamId: string, folder: FolderDto): Promise<void> {
  const values = {owner_uid: folder.ownerUid, name: folder.name, parent_folder_id: folder.parentFolderId,
    updated_at: folder.updatedAt};
  await executor.insert(fileFolders).values({id: folder.id, team_id: teamId, created_at: folder.createdAt, ...values})
    .onConflictDoUpdate({target: fileFolders.id, set: values, setWhere: eq(fileFolders.team_id, teamId)});
}

async function upsertFile(executor: RuntimeExecutor, teamId: string, file: FileDto): Promise<void> {
  const values = {owner_uid: file.ownerUid, display_name: file.displayName, folder_id: file.folderId,
    current_version_id: null, updated_at: file.updatedAt};
  await executor.insert(files).values({id: file.id, team_id: teamId, created_at: file.createdAt, ...values})
    .onConflictDoUpdate({target: files.id, set: values, setWhere: eq(files.team_id, teamId)});
}

async function upsertVersion(
  executor: RuntimeExecutor, teamId: string, version: VersionDto, storagePath: string,
): Promise<void> {
  const owner = await executor.select({team_id: files.team_id}).from(files)
    .where(eq(files.id, version.fileId)).get();
  const existing = await executor.select({file_id: fileVersions.file_id}).from(fileVersions)
    .where(eq(fileVersions.id, version.id)).get();
  if (owner?.team_id !== teamId || existing && existing.file_id !== version.fileId) {
    throw new InvalidTransferArchiveError("Die Dateiversion gehört nicht zur importierten Datei.");
  }
  const values = {file_id: version.fileId, created_by_uid: version.createdByUid, display_name: version.displayName,
    storage_path: storagePath, content_type: version.contentType, size_bytes: version.sizeBytes};
  await executor.insert(fileVersions).values({id: version.id, created_at: version.createdAt, ...values})
    .onConflictDoUpdate({target: fileVersions.id, set: values, setWhere: eq(fileVersions.file_id, version.fileId)});
}

async function removeAll(paths: readonly string[]): Promise<void> {
  await Promise.all(paths.map((absolutePath) => rm(absolutePath, {force: true})));
}
