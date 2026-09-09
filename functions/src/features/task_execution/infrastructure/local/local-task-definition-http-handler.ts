import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";

type TaskRow = SqlRow & {
  graph_json: string;
  id: string;
  objective: string;
  selected_node_id: string;
  title: string;
};

export class LocalTaskDefinitionHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly database: LocalSqlDatabase,
    private readonly teamId: string,
    private readonly userId: string,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    const path = pathFrom(request.url);
    if (request.method === "GET" && path === "/v1/tasks") return this.list();
    const taskId = taskIdFrom(path);
    if (taskId === null) return null;
    if (request.method === "PUT") return this.save(taskId, request.body);
    if (request.method === "DELETE") return this.delete(taskId);
    return null;
  }

  private async list(): Promise<LocalRuntimeResponse> {
    const rows = await this.database.all<TaskRow>(
      "SELECT id, title, objective, graph_json, selected_node_id FROM tasks WHERE team_id = ? ORDER BY updated_at DESC",
      [this.teamId],
    );
    return {body: {items: rows.map(taskFromRow)}, statusCode: 200};
  }

  private async save(taskId: string, body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const task = taskFromRequest(taskId, body);
      await this.database.run(upsertTaskSql(), [
        task.id,
        this.teamId,
        task.title,
        task.objective,
        JSON.stringify(task.graph),
        task.selectedNodeId,
        this.userId,
      ]);
      return {body: task, statusCode: 200};
    } catch (error) {
      if (error instanceof LocalTaskRequestError) return inputError(error.message);
      throw error;
    }
  }

  private async delete(taskId: string): Promise<LocalRuntimeResponse> {
    await this.database.run("DELETE FROM tasks WHERE team_id = ? AND id = ?", [this.teamId, taskId]);
    return {body: {}, statusCode: 204};
  }
}

function taskFromRequest(taskId: string, body: unknown): LocalTaskDocument {
  const input = recordFrom(body, "Die lokale Aufgabe erwartet ein Objekt.");
  if (input.id !== taskId) throw new LocalTaskRequestError("taskId stimmt nicht mit dem Pfad überein.");
  const graph = recordFrom(input.graph, "graph muss ein Objekt sein.");
  try {
    const task = {
      id: taskId,
      title: requiredString(input.title, "title"),
      objective: optionalString(input.objective),
      graph: graphFrom(graph),
      selectedNodeId: optionalString(input.selectedNodeId),
    };
    return {
      ...task,
    };
  } catch {
    throw new LocalTaskRequestError("Die Aufgabe enthält einen ungültigen Workflow-Graphen.");
  }
}

function graphFrom(value: Record<string, unknown>): Record<string, unknown> {
  if (!Array.isArray(value.nodes) || !Array.isArray(value.edges)) {
    throw new LocalTaskRequestError("graph benötigt Listen für nodes und edges.");
  }
  return {nodes: value.nodes, edges: value.edges};
}

function taskFromRow(row: TaskRow): LocalTaskDocument {
  return {
    id: row.id,
    title: row.title,
    objective: row.objective,
    graph: jsonRecord(row.graph_json),
    selectedNodeId: row.selected_node_id,
  };
}

function upsertTaskSql(): string {
  return `INSERT INTO tasks(id, team_id, title, objective, graph_json, selected_node_id, created_by_uid)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET title = excluded.title, objective = excluded.objective,
      graph_json = excluded.graph_json, selected_node_id = excluded.selected_node_id,
      updated_at = CURRENT_TIMESTAMP WHERE tasks.team_id = excluded.team_id`;
}

function pathFrom(url: string | undefined): string {
  return new URL(url ?? "/", "http://local-runtime").pathname;
}

function taskIdFrom(path: string): string | null {
  const match = /^\/v1\/tasks\/([^/]+)$/.exec(path);
  return match?.[1] ? decodeURIComponent(match[1]) : null;
}

function recordFrom(value: unknown, message: string): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new LocalTaskRequestError(message);
}

function requiredString(value: unknown, name: string): string {
  if (typeof value === "string" && value.trim().length > 0) return value;
  throw new LocalTaskRequestError(`${name} muss ein nicht leerer String sein.`);
}

function optionalString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function jsonRecord(value: string): Record<string, unknown> {
  try {
    return recordFrom(JSON.parse(value), "graph muss ein Objekt sein.");
  } catch {
    return {nodes: [], edges: []};
  }
}

function inputError(message: string): LocalRuntimeResponse {
  return {body: {error: message}, statusCode: 400};
}

class LocalTaskRequestError extends Error {}

type LocalTaskDocument = {
  graph: Record<string, unknown>;
  id: string;
  objective: string;
  selectedNodeId: string;
  title: string;
};
