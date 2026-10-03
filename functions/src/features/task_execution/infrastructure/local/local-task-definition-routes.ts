import {type FastifyPluginAsyncTypebox, type Static, Type} from "@fastify/type-provider-typebox";
import {ErrorResponse, IdParams, ItemsOf, JsonObject} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type TaskDefinition} from "../../domain/entities/task.js";
import {type TriggerCycleGuard} from "../../../scheduling/domain/usecases/trigger-cycle-guard.js";
import {type TaskDefinitionStore} from "../../domain/repositories/task-definition-store.js";

export type TaskDefinitionRoutesOptions = {
  store: TaskDefinitionStore;
  notifier: {publish(topic: string): void};
  cycleGuard: TriggerCycleGuard;
};

const Graph = Type.Object({nodes: Type.Array(JsonObject), edges: Type.Array(JsonObject)});
const TaskDocument = Type.Object({
  id: Type.String(), title: Type.String(), objective: Type.String(), selectedNodeId: Type.String(), graph: Graph,
  /** Nur beim Speichern: mögliche Auslöser-Schleifen, die der Nutzer kennen sollte. */
  warnings: Type.Optional(Type.Array(Type.String())),
});
const SaveTask = Type.Object({
  id: Type.String(),
  title: Type.String({minLength: 1, pattern: "\\S"}),
  objective: Type.Optional(Type.String()),
  selectedNodeId: Type.Optional(Type.String()),
  graph: Graph,
});
const TaskParams = IdParams("taskId");

export const taskDefinitionRoutes: FastifyPluginAsyncTypebox<TaskDefinitionRoutesOptions> = async (app, {store, notifier, cycleGuard}) => {
  const documentFrom = async (teamId: string, definition: TaskDefinition): Promise<Static<typeof TaskDocument>> => ({
    id: definition.id, title: definition.title, objective: definition.objective,
    selectedNodeId: await store.selectedNodeId(teamId, definition.id),
    graph: {nodes: definition.nodes, edges: definition.edges},
  });

  app.get("/v1/tasks", {schema: {response: {200: ItemsOf(TaskDocument)}}}, async (request) => {
    const {teamId} = request.workspace;
    const definitions = await store.list(teamId);
    return {items: await Promise.all(definitions.map((definition) => documentFrom(teamId, definition)))};
  });

  app.put("/v1/tasks/:taskId", {
    schema: {params: TaskParams, body: SaveTask, response: {200: TaskDocument, 400: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId, userId} = request.workspace;
    const {taskId} = request.params;
    if (request.body.id !== taskId) return reply.code(400).send({error: "taskId stimmt nicht mit dem Pfad überein."});
    const definition = definitionFrom(taskId, request.body);
    const verdict = await cycleGuard.checkTask(teamId, definition);
    if (verdict.blocked !== null) return reply.code(400).send({error: verdict.blocked});
    await store.save(teamId, userId, definition, request.body.selectedNodeId ?? "");
    notifier.publish("tasks");
    const document = await documentFrom(teamId, definition);
    return verdict.warnings.length === 0 ? document : {...document, warnings: verdict.warnings};
  });

  app.delete("/v1/tasks/:taskId", {schema: {params: TaskParams}}, async (request, reply) => {
    await store.delete(request.workspace.teamId, request.params.taskId);
    notifier.publish("tasks");
    return reply.code(204).send();
  });
};

/** Die Graph-Struktur prüft das Schema; die Knoten selbst bleiben Sache des Aufgaben-Modells. */
function definitionFrom(taskId: string, body: Static<typeof SaveTask>): TaskDefinition {
  return {
    id: taskId, title: body.title, objective: body.objective ?? "",
    nodes: body.graph.nodes as unknown as TaskDefinition["nodes"],
    edges: body.graph.edges as unknown as TaskDefinition["edges"],
  };
}
