import {and, desc, eq, sql} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {tasks, type Tasks} from "../../../../db/schema.js";
import {type TaskDefinition} from "../../domain/entities/task.js";
import {type TaskDefinitionStore} from "../../domain/repositories/task-definition-store.js";

type TaskDefinitionRow = Pick<Tasks, "graph_json" | "id" | "objective" | "selected_node_id" | "title">;

export class SQLiteTaskDefinitionStore implements TaskDefinitionStore {
  constructor(private readonly database: RuntimeExecutor) {}

  async delete(teamId: string, taskId: string): Promise<void> {
    await this.database.delete(tasks).where(and(eq(tasks.team_id, teamId), eq(tasks.id, taskId)));
  }

  async list(teamId: string): Promise<TaskDefinition[]> {
    const rows = await this.database.select({id: tasks.id, title: tasks.title, objective: tasks.objective, graph_json: tasks.graph_json, selected_node_id: tasks.selected_node_id}).from(tasks).where(eq(tasks.team_id, teamId)).orderBy(desc(tasks.updated_at));
    return rows.map(definitionFromRow);
  }

  async save(
    teamId: string,
    userId: string,
    definition: TaskDefinition,
    selectedNodeId: string,
  ): Promise<void> {
    await this.database.insert(tasks).values({id: definition.id, team_id: teamId, title: definition.title, objective: definition.objective, graph_json: JSON.stringify({nodes: definition.nodes, edges: definition.edges}), selected_node_id: selectedNodeId, created_by_uid: userId}).onConflictDoUpdate({target: tasks.id, set: {title: definition.title, objective: definition.objective, graph_json: JSON.stringify({nodes: definition.nodes, edges: definition.edges}), selected_node_id: selectedNodeId, updated_at: sql`CURRENT_TIMESTAMP`}, setWhere: eq(tasks.team_id, teamId)});
  }

  async selectedNodeId(teamId: string, taskId: string): Promise<string> {
    const row = (await this.database.select({selected_node_id: tasks.selected_node_id}).from(tasks).where(and(eq(tasks.team_id, teamId), eq(tasks.id, taskId))).get()) ?? null;
    return row?.selected_node_id ?? "";
  }
}

function definitionFromRow(row: TaskDefinitionRow): TaskDefinition {
  return {
    id: row.id, title: row.title, objective: row.objective,
    nodes: jsonList<TaskDefinition["nodes"][number]>(row.graph_json, "nodes"),
    edges: jsonList<TaskDefinition["edges"][number]>(row.graph_json, "edges"),
  };
}

function jsonList<T>(value: string, key: string): T[] {
  try {
    const parsed: unknown = JSON.parse(value);
    if (parsed !== null && typeof parsed === "object" && !Array.isArray(parsed)) {
      const item = (parsed as Record<string, unknown>)[key];
      if (Array.isArray(item)) return item as T[];
    }
  } catch {}
  return [];
}
