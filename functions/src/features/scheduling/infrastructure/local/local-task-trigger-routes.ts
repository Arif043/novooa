import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {and, eq, getTableColumns, sql} from "drizzle-orm";
import {type FastifyReply} from "fastify";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {tasks, taskTriggers} from "../../../../db/schema.js";
import {ErrorResponse, IdParams, ItemsOf, JsonObject, NonEmptyString} from "../../../../shared/local/local-runtime-http-schemas.js";
import {invalidResponse, LocalTaskTriggerError, triggerFromRequest, triggerFromRow} from "./local-task-trigger-http-support.js";

export type TaskTriggerRoutesOptions = {
  database: RuntimeExecutor;
  notifier: {publish(topic: string): void};
};

const Timestamp = Type.Union([Type.String(), Type.Null()]);
const TaskTrigger = Type.Object({
  id: Type.String(), teamId: Type.String(), taskId: Type.String(), taskTitle: Type.String(),
  type: Type.String(), enabled: Type.Boolean(), config: JsonObject, eventConfig: JsonObject, policy: JsonObject,
  nextRunAt: Timestamp, lastRunAt: Timestamp, lastRunId: Type.Union([Type.String(), Type.Null()]),
});
/** Struktur hier, Fachregeln (gültiger Zeitplan, nächster Lauf) in `triggerFromRequest`. */
const CreateTrigger = Type.Object({
  taskId: NonEmptyString({maxLength: 200}),
  type: Type.Union([Type.Literal("schedule"), Type.Literal("event")]),
  enabled: Type.Optional(Type.Boolean()),
  config: Type.Optional(JsonObject), eventConfig: Type.Optional(JsonObject), policy: Type.Optional(JsonObject),
});
const TriggerParams = IdParams("triggerId");
const TriggerResponses = {200: TaskTrigger, 400: ErrorResponse, 404: ErrorResponse};

export const taskTriggerRoutes: FastifyPluginAsyncTypebox<TaskTriggerRoutesOptions> = async (app, {database, notifier}) => {
  app.get("/v1/task-triggers", {schema: {response: {200: ItemsOf(TaskTrigger)}}}, async (request) => {
    const rows = await triggerQuery(database).where(eq(taskTriggers.team_id, request.workspace.teamId))
      .orderBy(sql`${taskTriggers.next_run_at} IS NULL`, taskTriggers.next_run_at);
    return {items: rows.map(triggerFromRow)};
  });

  app.post("/v1/task-triggers", {schema: {body: CreateTrigger, response: {...TriggerResponses, 201: TaskTrigger}}},
    async (request, reply) => {
      const {teamId, userId} = request.workspace;
      try {
        const input = triggerFromRequest(request.body);
        await ensureTask(database, teamId, input.taskId);
        const id = randomUUID();
        await database.insert(taskTriggers).values({id, team_id: teamId, task_id: input.taskId, type: input.type,
          enabled: input.enabled ? 1 : 0, config_json: JSON.stringify(input.config),
          event_config_json: JSON.stringify(input.eventConfig), policy_json: JSON.stringify(input.policy),
          next_run_at: input.nextRunAt?.toISOString() ?? null, created_by_uid: userId});
        notifier.publish("task-triggers");
        return triggerById(database, teamId, id, 201, reply);
      } catch (error) {
        return invalidResponse(error, reply);
      }
    });

  app.put("/v1/task-triggers/:triggerId/enabled", {
    schema: {params: TriggerParams, body: Type.Object({enabled: Type.Boolean()}), response: TriggerResponses},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    await database.update(taskTriggers).set({enabled: request.body.enabled ? 1 : 0, updated_at: sql`CURRENT_TIMESTAMP`})
      .where(and(eq(taskTriggers.team_id, teamId), eq(taskTriggers.id, request.params.triggerId)));
    notifier.publish("task-triggers");
    return triggerById(database, teamId, request.params.triggerId, 200, reply);
  });

  app.delete("/v1/task-triggers/:triggerId", {schema: {params: TriggerParams}},
    async (request, reply) => {
      await database.delete(taskTriggers)
        .where(and(eq(taskTriggers.team_id, request.workspace.teamId), eq(taskTriggers.id, request.params.triggerId)));
      notifier.publish("task-triggers");
      return reply.code(204).send();
    });
};

async function ensureTask(database: RuntimeExecutor, teamId: string, taskId: string): Promise<void> {
  const task = await database.select({id: tasks.id}).from(tasks).where(and(eq(tasks.team_id, teamId), eq(tasks.id, taskId))).get();
  if (task === undefined) throw new LocalTaskTriggerError("Die Aufgabe existiert nicht.");
}

async function triggerById(
  database: RuntimeExecutor, teamId: string, id: string, statusCode: 200 | 201, reply: FastifyReply,
): Promise<FastifyReply> {
  const row = await triggerQuery(database).where(and(eq(taskTriggers.team_id, teamId), eq(taskTriggers.id, id))).get();
  return row === undefined
    ? reply.code(404).send({error: "Zeitplan nicht gefunden."})
    : reply.code(statusCode).send(triggerFromRow(row));
}

function triggerQuery(database: RuntimeExecutor) {
  return database.select({...getTableColumns(taskTriggers), task_title: tasks.title})
    .from(taskTriggers).innerJoin(tasks, eq(tasks.id, taskTriggers.task_id));
}
