import {eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {workspaceFileSettings} from "../../../../db/schema.js";
import {DEFAULT_FILE_VERSION_LIMIT} from "../../domain/entities/file-version-rotation.js";
import {type FileSettingsStore} from "../../domain/repositories/file-settings-store.js";

export class SQLiteFileSettingsStore implements FileSettingsStore {
  constructor(private readonly database: RuntimeExecutor) {}

  async loadVersionLimit(teamId: string): Promise<number> {
    const row = await this.database.select().from(workspaceFileSettings)
      .where(eq(workspaceFileSettings.team_id, teamId)).get();
    return row?.version_limit ?? DEFAULT_FILE_VERSION_LIMIT;
  }

  async saveVersionLimit(teamId: string, limit: number): Promise<void> {
    await this.database.insert(workspaceFileSettings).values({team_id: teamId, version_limit: limit})
      .onConflictDoUpdate({target: workspaceFileSettings.team_id, set: {version_limit: limit}});
  }
}
