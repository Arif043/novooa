import {UserFacingError} from "genkit";
import {
  taskDefinitionSchema,
  type TaskDefinition,
} from "../task-runner/task-definition.js";
import {type TaskStore} from "../task-runner/stores/task-store.js";
import {type LocalSqlDatabase, type SqlRow} from "./local-sql-database.js";

type TaskRow = SqlRow & {
  id: string;
  title: string;
  objective: string;
  graph_json: string;
};

export class SQLiteTaskStore implements TaskStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  async loadTask(teamId: string, taskId: string): Promise<TaskDefinition> {
    const taskOrNull = await this.database.get<TaskRow>(
      "SELECT id, title, objective, graph_json FROM tasks WHERE team_id = ? AND id = ?",
      [teamId, taskId],
    );
    if (taskOrNull === null) throw taskNotFound();
    return taskFromRow(taskOrNull);
  }
}

function taskFromRow(row: TaskRow): TaskDefinition {
  const graph = jsonObject(row.graph_json);
  return taskDefinitionSchema.parse({
    id: row.id,
    title: row.title,
    objective: row.objective,
    nodes: Array.isArray(graph.nodes) ? graph.nodes : [],
    edges: Array.isArray(graph.edges) ? graph.edges : [],
  });
}

function taskNotFound(): UserFacingError {
  return new UserFacingError("NOT_FOUND", "Aufgabe wurde nicht gefunden.");
}

function jsonObject(value: string): Record<string, unknown> {
  const parsed: unknown = JSON.parse(value);
  if (typeof parsed === "object" && parsed !== null && !Array.isArray(parsed)) {
    return parsed as Record<string, unknown>;
  }
  return {};
}
