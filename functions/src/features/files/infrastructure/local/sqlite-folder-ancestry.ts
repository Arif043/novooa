import {and, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {fileFolders} from "../../../../db/schema.js";
import {type FolderAncestry} from "../../domain/repositories/folder-ancestry.js";

export class SQLiteFolderAncestry implements FolderAncestry {
  constructor(private readonly database: RuntimeExecutor) {}

  async chainOf(teamId: string, folderId: string): Promise<string[]> {
    const chain: string[] = [];
    let current: string | null = folderId;
    while (current !== null && !chain.includes(current)) {
      chain.push(current);
      const row: {parent: string | null} | undefined = await this.database
        .select({parent: fileFolders.parent_folder_id}).from(fileFolders)
        .where(and(eq(fileFolders.team_id, teamId), eq(fileFolders.id, current))).get();
      current = row?.parent ?? null;
    }
    return chain;
  }
}
