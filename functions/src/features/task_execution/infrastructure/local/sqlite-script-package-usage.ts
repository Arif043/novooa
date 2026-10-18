import {type RuntimeDatabase} from "../../../../db/database.js";
import {tasks} from "../../../../db/schema.js";
import {scriptPackageListsOf} from "../../domain/services/used-script-packages.js";
import {type ScriptPackageUsage} from "./script-package-jobs.js";

/**
 * Welche Paketlisten Script-Bausteine noch verwenden — über alle Arbeitsbereiche,
 * denn die Umgebungen liegen einmal pro Runtime.
 */
export function sqliteScriptPackageUsage(database: RuntimeDatabase): ScriptPackageUsage {
  return async () => {
    const rows = await database.select({graph_json: tasks.graph_json}).from(tasks);
    return rows.flatMap((row) => scriptPackageListsOf(graphOf(row.graph_json)));
  };
}

function graphOf(json: string): {nodes: []} {
  const parsed = JSON.parse(json) as unknown;
  const nodes = typeof parsed === "object" && parsed !== null ? (parsed as {nodes?: unknown}).nodes : undefined;
  return {nodes: Array.isArray(nodes) ? nodes as [] : []};
}
