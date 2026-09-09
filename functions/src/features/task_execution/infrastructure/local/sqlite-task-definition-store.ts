import {type TaskDefinition} from "../../domain/entities/task.js";
import {type TaskDefinitionStore} from "../../domain/repositories/task-definition-store.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";

type TaskDefinitionRow = SqlRow & {
  graph_json: string;
  id: string;
  objective: string;
  selected_node_id: string;
  title: string;
};

export class SQLiteTaskDefinitionStore implements TaskDefinitionStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  async delete(teamId: string, taskId: string): Promise<void> {
    await this.database.run("DELETE FROM tasks WHERE team_id = ? AND id = ?", [teamId, taskId]);
  }

  async list(teamId: string): Promise<TaskDefinition[]> {
    const rows = await this.database.all<TaskDefinitionRow>(
      "SELECT id, title, objective, graph_json, selected_node_id FROM tasks WHERE team_id = ? ORDER BY updated_at DESC",
      [teamId],
    );
    return rows.map(definitionFromRow);
  }

  async save(
    teamId: string,
    userId: string,
    definition: TaskDefinition,
    selectedNodeId: string,
  ): Promise<void> {
    await this.database.run(upsertTaskDefinitionSql(), [
      definition.id, teamId, definition.title, definition.objective,
      JSON.stringify({nodes: definition.nodes, edges: definition.edges}), selectedNodeId, userId,
    ]);
  }

  async selectedNodeId(teamId: string, taskId: string): Promise<string> {
    const row = await this.database.get<{selected_node_id: string}>(
      "SELECT selected_node_id FROM tasks WHERE team_id = ? AND id = ?",
      [teamId, taskId],
    );
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

function upsertTaskDefinitionSql(): string {
  return `INSERT INTO tasks(id, team_id, title, objective, graph_json, selected_node_id, created_by_uid)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET title = excluded.title, objective = excluded.objective,
      graph_json = excluded.graph_json, selected_node_id = excluded.selected_node_id,
      updated_at = CURRENT_TIMESTAMP WHERE tasks.team_id = excluded.team_id`;
}
