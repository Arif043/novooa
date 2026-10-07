import {and, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {fileFolders} from "../../../../db/schema.js";
import {folderTeamId} from "./local-folder-team.js";
import {type FolderAncestry} from "../../domain/repositories/folder-ancestry.js";

export class SQLiteFolderAncestry implements FolderAncestry {
  constructor(private readonly database: RuntimeExecutor) {}

  async parentsOf(teamId: string): Promise<ReadonlyMap<string, string | null>> {
    const rows = await this.database.select({id: fileFolders.id, parent: fileFolders.parent_folder_id})
      .from(fileFolders).where(eq(folderTeamId, teamId));
    return new Map(rows.map((row) => [row.id, row.parent]));
  }

  async chainOf(teamId: string, folderId: string): Promise<string[]> {
    const chain: string[] = [];
    let current: string | null = folderId;
    while (current !== null && !chain.includes(current)) {
      chain.push(current);
      const row: {parent: string | null} | undefined = await this.database
        .select({parent: fileFolders.parent_folder_id}).from(fileFolders)
        .where(and(eq(folderTeamId, teamId), eq(fileFolders.id, current))).get();
      current = row?.parent ?? null;
    }
    return chain;
  }
}
