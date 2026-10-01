import {eq} from "drizzle-orm";
import {createReadStream} from "node:fs";
import {access} from "node:fs/promises";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {fileFolders, files, fileVersions, type FileVersions} from "../../../../db/schema.js";
import {localFilePath} from "../../../files/infrastructure/local/local-file-path.js";
import {isTeamStoragePath} from "../../domain/entities/transfer-team-mapping.js";
import {
  transferBlobEntry,
  transferDataEntry,
  type TransferArchiveWriter,
} from "../../domain/repositories/transfer-archive.js";
import {type TransferSection} from "../../domain/repositories/transfer-section.js";
import {fileDtoFrom, folderDtoFrom, versionDtoFrom, type FilesTransferPayload} from "./files-transfer-payload.js";

export class SqliteFilesTransferSection implements TransferSection {
  readonly category = "files" as const;

  constructor(
    private readonly database: RuntimeExecutor,
    private readonly rootDirectory: string,
  ) {}

  async exportTo(writer: TransferArchiveWriter, teamId: string): Promise<number> {
    const payload = await this.payloadFor(teamId);
    await writer.addJson(transferDataEntry("files"), payload);
    for (const version of payload.versions) {
      const content = createReadStream(localFilePath(this.rootDirectory, version.storagePath));
      await writer.addBlob(transferBlobEntry(version.storagePath), content);
    }
    return payload.files.length;
  }

  private async payloadFor(teamId: string): Promise<FilesTransferPayload> {
    const folders = await this.database.select().from(fileFolders).where(eq(fileFolders.team_id, teamId));
    const fileRows = await this.database.select().from(files).where(eq(files.team_id, teamId));
    return {
      folders: folders.map(folderDtoFrom),
      files: fileRows.filter((row) => isTeamStoragePath(teamId, row.storage_path)).map(fileDtoFrom),
      versions: (await this.exportableVersions(teamId)).map(versionDtoFrom),
    };
  }

  /** Versionen ohne Datei auf der Platte würden den späteren Import blockieren. */
  private async exportableVersions(teamId: string): Promise<FileVersions[]> {
    const rows = await this.database.select().from(fileVersions).where(eq(fileVersions.team_id, teamId));
    const exportable: FileVersions[] = [];
    for (const row of rows) {
      if (isTeamStoragePath(teamId, row.storage_path) && await this.exists(row.storage_path)) exportable.push(row);
    }
    return exportable;
  }

  private async exists(storagePath: string): Promise<boolean> {
    return access(localFilePath(this.rootDirectory, storagePath)).then(() => true, () => false);
  }
}
