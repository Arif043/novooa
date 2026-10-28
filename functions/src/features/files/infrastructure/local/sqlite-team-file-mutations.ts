import {and, eq, isNull, ne, sql} from "drizzle-orm";
import {err, ok, type Result} from "neverthrow";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {files} from "../../../../db/schema.js";
import {uniqueFileNameFor} from "../../domain/entities/unique-file-name.js";
import {type TeamFileStore, type WrittenFile} from "../../domain/repositories/team-file-store.js";
import {type TeamFileContentReader} from "../../domain/repositories/team-file-content-reader.js";
import {fileLocation, fileTeamId} from "./sqlite-file-team.js";
import {folderExists} from "./sqlite-folder-reference.js";

export type FileMutationFailure = "fileNotFound" | "versionNotFound" | "folderNotFound" | "nameTaken";

/** `undefined` lässt Name bzw. Ordner unverändert; `folderId: null` ist die oberste Ebene. */
export type FileChange = {name?: string; folderId?: string | null};

type Files = Pick<TeamFileStore, "writeTeamFile" | "loadTeamFile"> & Pick<TeamFileContentReader, "readTeamFileContent">;
type FileRow = {displayName: string; folderId: string | null};

/**
 * Umbenennen, Verschieben, Kopieren und Wiederherstellen. Umbenennen und Verschieben ändern nur die Datei,
 * nie ihre Versionen; Kopie und Wiederherstellen schreiben über den Dateispeicher (Rotation, Ereignisse).
 */
export class SQLiteTeamFileMutations {
  constructor(private readonly database: RuntimeExecutor, private readonly files: Files) {}

  async change(teamId: string, fileId: string, change: FileChange): Promise<Result<void, FileMutationFailure>> {
    const file = await this.fileRow(teamId, fileId);
    if (file === null) return err("fileNotFound");
    const folderId = change.folderId === undefined ? file.folderId : change.folderId;
    const name = change.name?.trim() ?? file.displayName;
    if (!await folderExists(this.database, teamId, folderId)) return err("folderNotFound");
    // „Datei schreiben“ findet Dateien über den Namen; doppelte Namen in einem Ordner wären mehrdeutig.
    if ((await this.namesIn(teamId, folderId, fileId)).has(name)) return err("nameTaken");
    await this.database.update(files).set({display_name: name, ...fileLocation(teamId, folderId), updated_at: sql`CURRENT_TIMESTAMP`})
      .where(and(eq(fileTeamId, teamId), eq(files.id, fileId)));
    return ok(undefined);
  }

  async copy(teamId: string, fileId: string, target: FileChange): Promise<Result<WrittenFile, FileMutationFailure>> {
    const source = await this.fileRow(teamId, fileId);
    if (source === null) return err("fileNotFound");
    const folderId = target.folderId === undefined ? source.folderId : target.folderId;
    if (!await folderExists(this.database, teamId, folderId)) return err("folderNotFound");
    const current = await this.files.loadTeamFile(teamId, fileId);
    const content = await this.files.readTeamFileContent(teamId, fileId, current.versionId);
    const fileName = uniqueFileNameFor(target.name?.trim() ?? source.displayName, await this.namesIn(teamId, folderId, null));
    return ok(await this.files.writeTeamFile({
      teamId, fileName, contentType: content.contentType, content: content.content, folderId, targetFileId: null, forceNewFile: true,
    }));
  }

  /** Die alte Version wird Inhalt einer neuen aktuellen Version; gespeicherte Versionen bleiben unverändert. */
  async restore(teamId: string, fileId: string, versionId: string): Promise<Result<WrittenFile, FileMutationFailure>> {
    const file = await this.fileRow(teamId, fileId);
    if (file === null) return err("fileNotFound");
    const version = await this.files.readTeamFileContent(teamId, fileId, versionId).catch(() => null);
    if (version === null) return err("versionNotFound");
    return ok(await this.files.writeTeamFile({
      teamId, fileName: file.displayName, contentType: version.contentType, content: version.content, targetFileId: fileId,
    }));
  }

  private async fileRow(teamId: string, fileId: string): Promise<FileRow | null> {
    const row = await this.database.select({displayName: files.display_name, folderId: files.folder_id}).from(files)
      .where(and(eq(fileTeamId, teamId), eq(files.id, fileId))).get();
    return row ?? null;
  }

  private async namesIn(teamId: string, folderId: string | null, exceptFileId: string | null): Promise<Set<string>> {
    const rows = await this.database.select({name: files.display_name}).from(files).where(and(
      eq(fileTeamId, teamId),
      folderId === null ? isNull(files.folder_id) : eq(files.folder_id, folderId),
      exceptFileId === null ? undefined : ne(files.id, exceptFileId),
    ));
    return new Set(rows.map((row) => row.name));
  }
}
