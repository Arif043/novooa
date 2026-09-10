import {UserFacingError} from "genkit";
import {type TaskDefinition} from "../../domain/entities/task.js";
import {taskDefinitionSchema} from "../genkit/runner/task-definition.js";
import {type TaskStore} from "../../domain/repositories/task-store.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";

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
    ...graphFromStorage(graph),
  });
}

function graphFromStorage(value: Record<string, unknown>): Record<string, unknown> {
  return {
    nodes: Array.isArray(value.nodes) ? value.nodes.map(nodeFromStorage) : [],
    edges: Array.isArray(value.edges) ? value.edges : [],
  };
}

function nodeFromStorage(value: unknown): Record<string, unknown> {
  const node = jsonObjectValue(value);
  const config = configFromStorage(node.config);
  return {...node, primitive: stringFrom(config.primitive), config};
}

function configFromStorage(value: unknown): Record<string, unknown> {
  const config = jsonObjectValue(value);
  const primitive = stringFrom(config.primitive);
  if (primitive === "conditionalFlow") return conditionalConfig(config, primitive);
  if (primitive === "forEach") return forEachConfig(config, primitive);
  return {...config, primitive};
}

function conditionalConfig(
  config: Record<string, unknown>,
  primitive: string,
): Record<string, unknown> {
  const branches = Array.isArray(config.branches) ? config.branches : [];
  return {
    ...config,
    primitive,
    branches: branches.map(branchFromStorage),
  };
}

function branchFromStorage(value: unknown): Record<string, unknown> {
  const branch = jsonObjectValue(value);
  return {...branch, graph: graphFromStorage(jsonObjectValue(branch.graph))};
}

function forEachConfig(
  config: Record<string, unknown>,
  primitive: string,
): Record<string, unknown> {
  return {
    ...config,
    primitive,
    graph: graphFromStorage(jsonObjectValue(config.graph)),
  };
}

function stringFrom(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function taskNotFound(): UserFacingError {
  return new UserFacingError("NOT_FOUND", "Aufgabe wurde nicht gefunden.");
}

function jsonObject(value: string): Record<string, unknown> {
  return jsonObjectValue(JSON.parse(value));
}

function jsonObjectValue(value: unknown): Record<string, unknown> {
  if (typeof value === "object" && value !== null && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}
