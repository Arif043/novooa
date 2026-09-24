import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {type TaskDefinition} from "../../domain/entities/task.js";
import {type TaskDefinitionStore} from "../../domain/repositories/task-definition-store.js";
import {type LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";

export class LocalTaskDefinitionHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly store: TaskDefinitionStore,
    private readonly teamId: string,
    private readonly userId: string,
    private readonly notifier: LocalRuntimeRealtimeNotifier,
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
    const definitions = await this.store.list(this.teamId);
    const items = await Promise.all(definitions.map((definition) => this.documentFrom(definition)));
    return {body: {items}, statusCode: 200};
  }

  private async save(taskId: string, body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const task = taskFromRequest(taskId, body);
      await this.store.save(this.teamId, this.userId, task.definition, task.selectedNodeId);
      this.notifier.publish("tasks");
      return {body: await this.documentFrom(task.definition), statusCode: 200};
    } catch (error) {
      if (error instanceof LocalTaskRequestError) return inputError(error.message);
      throw error;
    }
  }

  private async delete(taskId: string): Promise<LocalRuntimeResponse> {
    await this.store.delete(this.teamId, taskId);
    this.notifier.publish("tasks");
    return {body: {}, statusCode: 204};
  }

  private async documentFrom(definition: TaskDefinition): Promise<Record<string, unknown>> {
    return documentFrom(definition, await this.store.selectedNodeId(this.teamId, definition.id));
  }
}

function taskFromRequest(taskId: string, body: unknown): {definition: TaskDefinition; selectedNodeId: string} {
  const input = recordFrom(body, "Die lokale Aufgabe erwartet ein Objekt.");
  if (input.id !== taskId) throw new LocalTaskRequestError("taskId stimmt nicht mit dem Pfad überein.");
  const graph = recordFrom(input.graph, "graph muss ein Objekt sein.");
  try {
    const definition: TaskDefinition = {
      id: taskId,
      title: requiredString(input.title, "title"),
      objective: optionalString(input.objective),
      ...graphFrom(graph),
    };
    return {definition, selectedNodeId: optionalString(input.selectedNodeId)};
  } catch {
    throw new LocalTaskRequestError("Die Aufgabe enthält einen ungültigen Workflow-Graphen.");
  }
}

function graphFrom(value: Record<string, unknown>): Pick<TaskDefinition, "nodes" | "edges"> {
  if (!Array.isArray(value.nodes) || !Array.isArray(value.edges)) {
    throw new LocalTaskRequestError("graph benötigt Listen für nodes und edges.");
  }
  return {
    nodes: value.nodes as TaskDefinition["nodes"],
    edges: value.edges as TaskDefinition["edges"],
  };
}

function documentFrom(definition: TaskDefinition, selectedNodeId: string): Record<string, unknown> {
  return {
    id: definition.id, title: definition.title, objective: definition.objective,
    selectedNodeId,
    graph: {nodes: definition.nodes, edges: definition.edges},
  };
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

function inputError(message: string): LocalRuntimeResponse {
  return {body: {error: message}, statusCode: 400};
}

class LocalTaskRequestError extends Error {}
