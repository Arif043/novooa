import {and, eq, sql} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {files, fileVersions} from "../../../../db/schema.js";
import {type WrittenFile} from "../../domain/repositories/team-file-store.js";
import {fileTeamId, fileLocation} from "./sqlite-file-team.js";
import {ensureFolder} from "./sqlite-folder-reference.js";

export async function writeFileMetadata(database: RuntimeExecutor, teamId: string, file: WrittenFile): Promise<void> {
  await database.transaction(async (tx) => {
    await ensureFolder(tx, teamId, file.folderId);
    await upsertFile(tx, teamId, file);
    await insertVersion(tx, file);
    await tx.update(files).set({current_version_id: file.versionId, updated_at: sql`CURRENT_TIMESTAMP`})
      .where(and(eq(files.id, file.fileId), eq(fileTeamId, teamId)));
  });
}

async function upsertFile(database: RuntimeExecutor, teamId: string, file: WrittenFile) {
  const existing = await database.select({team_id: fileTeamId}).from(files).where(eq(files.id, file.fileId)).get();
  if (existing && existing.team_id !== teamId) throw new Error("Die Datei gehört zu einem anderen Team.");
  await database.insert(files).values({id: file.fileId, ...fileLocation(teamId, file.folderId), owner_uid: file.ownerUid,
    display_name: file.displayName}).onConflictDoNothing({target: files.id});
}

async function insertVersion(database: RuntimeExecutor, file: WrittenFile) {
  await database.insert(fileVersions).values({id: file.versionId, file_id: file.fileId,
    created_by_uid: "system", display_name: file.displayName, storage_path: file.storagePath,
    content_type: file.contentType, size_bytes: file.sizeBytes});
}
