import {and, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {workspacePlugins} from "../../../../db/schema.js";
import {type PluginActivationStore} from "../../domain/repositories/plugin-activation-store.js";

export class SQLitePluginActivationStore implements PluginActivationStore {
  constructor(private readonly database: RuntimeExecutor, private readonly now: () => Date = () => new Date()) {}

  async enabledPlugins(teamId: string): Promise<ReadonlyMap<string, string>> {
    const rows = await this.database.select().from(workspacePlugins).where(eq(workspacePlugins.team_id, teamId));
    return new Map(rows.map((row) => [row.plugin_id, row.enabled_at]));
  }

  async isEnabled(teamId: string, pluginId: string): Promise<boolean> {
    const row = await this.database.select({id: workspacePlugins.plugin_id}).from(workspacePlugins)
      .where(and(eq(workspacePlugins.team_id, teamId), eq(workspacePlugins.plugin_id, pluginId))).get();
    return row !== undefined;
  }

  /** Erneutes Aktivieren behält den ersten Zeitpunkt. */
  async enable(teamId: string, pluginId: string, uid: string): Promise<void> {
    await this.database.insert(workspacePlugins)
      .values({team_id: teamId, plugin_id: pluginId, enabled_at: this.now().toISOString(), enabled_by_uid: uid})
      .onConflictDoNothing();
  }

  async disable(teamId: string, pluginId: string): Promise<void> {
    await this.database.delete(workspacePlugins)
      .where(and(eq(workspacePlugins.team_id, teamId), eq(workspacePlugins.plugin_id, pluginId)));
  }
}
