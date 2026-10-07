import {and, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {fileFolders} from "../../../../db/schema.js";

export async function folderExists(database: RuntimeExecutor, teamId: string, folderId: string | null): Promise<boolean> {
  if (folderId === null) return true;
  const folder = await database.select({id: fileFolders.id}).from(fileFolders)
    .where(and(eq(fileFolders.team_id, teamId), eq(fileFolders.id, folderId))).get();
  return folder !== undefined;
}

export async function ensureFolder(database: RuntimeExecutor, teamId: string, folderId: string | null): Promise<void> {
  if (!await folderExists(database, teamId, folderId)) {
    throw new Error("Das Verzeichnis existiert nicht oder gehört zu einem anderen Team.");
  }
}
