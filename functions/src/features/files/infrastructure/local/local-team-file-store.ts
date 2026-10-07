import {and, eq, inArray, isNull, sql} from "drizzle-orm";
import {readFile, rm} from "node:fs/promises";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {files, fileVersions, type Files} from "../../../../db/schema.js";
import {type NodeAttachment} from "../../../task_execution/domain/entities/attachments.js";
import {versionsToRotateOut} from "../../domain/entities/file-version-rotation.js";
import {noFileEventPublisher, type FileEventPublisher} from "../../domain/repositories/file-event-publisher.js";
import {type FileSettingsStore} from "../../domain/repositories/file-settings-store.js";
import {writtenEventFrom, deletedEventFrom, newFileFrom, versionFromExisting} from "./local-file-mappers.js";
import {currentFilesQuery, fileVersionsQuery} from "./local-file-queries.js";
import {localFilePath, writeLocalFile} from "./local-file-path.js";
import {
  type TeamFileContent,
  type TeamFileContentReader,
} from "../../domain/repositories/team-file-content-reader.js";
import {
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
    private readonly settings: FileSettingsStore,
    private readonly events: FileEventPublisher = noFileEventPublisher,
  ) {}

  async writeTeamFile(input: WriteTeamFileInput): Promise<WrittenFile> {
    const file = await this.writtenFileFrom(input);
    await writeLocalFile(this.rootDirectory, file.storagePath, input.content);
    await this.writeMetadata(input.teamId, file);
    await this.rotateVersions(input.teamId, file);
    await this.events.publish(writtenEventFrom(input.teamId, file, input.triggerChain ?? []));
    return file;
  }

  /** Entfernt die Datei samt aller Versionen. `false`, wenn sie nicht existiert. */
  async deleteTeamFile(teamId: string, fileId: string): Promise<boolean> {
    const file = await this.fileRowFor(teamId, fileId);
    if (file === null) return false;
    const versions = await fileVersionsQuery(this.database)
      .where(and(eq(files.team_id, teamId), eq(fileVersions.file_id, fileId)));
    await this.database.transaction(async (tx) => {
      await tx.delete(files).where(and(eq(files.team_id, teamId), eq(files.id, fileId)));
    });
    await Promise.all(versions.map((version) =>
      rm(localFilePath(this.rootDirectory, version.storage_path), {force: true})));
    await this.events.publish(deletedEventFrom(teamId, file));
    return true;
  }

  private async fileRowFor(teamId: string, fileId: string) {
    const row = await currentFilesQuery(this.database).where(and(eq(files.team_id, teamId), eq(files.id, fileId))).get();
    return row ?? null;
  }

  async readTextFile(teamId: string, file: NodeAttachment): Promise<string> {
    ensureTeamFile(file, teamId);
    return readFile(localFilePath(this.rootDirectory, file.storagePath), "utf8");
  }

  async loadTeamFile(
    teamId: string,
    fileId: string,
  ): Promise<StoredTeamFile> {
    const row = (await currentFilesQuery(this.database).where(and(eq(files.team_id, teamId), eq(files.id, fileId))).get()) ?? null;
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
    const file = (await fileVersionsQuery(this.database).where(and(eq(files.team_id, teamId), eq(fileVersions.file_id, fileId), eq(fileVersions.id, versionId))).get()) ?? null;
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
    const stale = await this.staleVersions(teamId, file);
    if (stale.length === 0) return;
    await this.database.delete(fileVersions).where(and(
      eq(fileVersions.file_id, file.fileId),
      inArray(fileVersions.id, stale.map((version) => version.id)),
    ));
    await Promise.all(stale.map((version) =>
      rm(localFilePath(this.rootDirectory, version.storage_path), {force: true})));
  }

  private async staleVersions(teamId: string, file: WrittenFile) {
    const rows = await fileVersionsQuery(this.database)
      .where(and(eq(files.team_id, teamId), eq(fileVersions.file_id, file.fileId)))
      // created_at hat Sekundenauflösung; rowid-Reihenfolge entscheidet bei Gleichstand.
      .orderBy(sql`${fileVersions}.rowid DESC`);
    return versionsToRotateOut(
      rows.map((row) => ({...row, createdAt: Date.parse(`${row.created_at.replace(" ", "T")}Z`)})),
      await this.settings.loadVersionLimit(teamId), file.versionId,
    );
  }

  private async writeMetadata(teamId: string, file: WrittenFile) {
    await this.database.transaction(async (tx) => {
      await upsertFile(tx, teamId, file);
      await insertVersion(tx, file);
      await tx.update(files).set({current_version_id: file.versionId, updated_at: sql`CURRENT_TIMESTAMP`})
        .where(and(eq(files.id, file.fileId), eq(files.team_id, teamId)));
    });
  }
}

async function upsertFile(
  database: RuntimeExecutor,
  teamId: string,
  file: WrittenFile,
) {
  await database.insert(files).values({id: file.fileId, team_id: teamId, owner_uid: file.ownerUid,
    display_name: file.displayName, folder_id: file.folderId})
    .onConflictDoNothing({target: files.id});
}

async function insertVersion(database: RuntimeExecutor, file: WrittenFile) {
  await database.insert(fileVersions).values({id: file.versionId, file_id: file.fileId,
    created_by_uid: "system", display_name: file.displayName, storage_path: file.storagePath,
    content_type: file.contentType, size_bytes: file.sizeBytes});
}

function ensureTeamFile(file: NodeAttachment, teamId: string): void {
  if (file.storagePath.startsWith(`teams/${teamId}/files/`)) return;
  throw new Error("Datei lesen: Die Datei gehört nicht zum aktuellen Team.");
}

function existingFileFrom(row: FileRow): ExistingFile {
  return {fileId: row.id, ownerUid: row.owner_uid, folderId: row.folder_id};
}
