import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {and, eq, sql} from "drizzle-orm";
import {type FastifyReply} from "fastify";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {tasks, taskTriggers} from "../../../../db/schema.js";
import {triggerQuery, triggerMatching} from "./sqlite-task-trigger-queries.js";
import {ErrorResponse, IdParams, ItemsOf, JsonObject, NonEmptyString} from "../../../../shared/local/local-runtime-http-schemas.js";
import {eventTriggerConfigFrom} from "../../domain/entities/event-trigger-config.js";
import {generateWebhookToken, webhookConfigFrom} from "../../domain/entities/webhook-config.js";
import {webhookSecretRef, type WebhookSecretStore} from "../../domain/repositories/webhook-secret-store.js";
import {type TriggerCycleGuard} from "../../domain/usecases/trigger-cycle-guard.js";
import {invalidResponse, LocalTaskTriggerError, triggerFromRequest, triggerFromRow, type TriggerInput} from "./local-task-trigger-http-support.js";

export type TaskTriggerRoutesOptions = {
  database: RuntimeExecutor;
  notifier: {publish(topic: string): void};
  cycleGuard: TriggerCycleGuard;
  webhookSecrets: WebhookSecretStore;
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

export const taskTriggerRoutes: FastifyPluginAsyncTypebox<TaskTriggerRoutesOptions> = async (app, {database, notifier, cycleGuard, webhookSecrets}) => {
  app.get("/v1/task-triggers", {schema: {response: {200: ItemsOf(TaskTrigger)}}}, async (request) => {
    const rows = await triggerQuery(database).where(eq(tasks.team_id, request.workspace.teamId))
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
        const blocked = input.enabled ? await blockedReason(cycleGuard, teamId, id, input) : null;
        if (blocked !== null) return reply.code(400).send({error: blocked});
        await database.transaction(async (tx) => {
          await ensureTask(tx, teamId, input.taskId);
          await tx.insert(taskTriggers).values({id, task_id: input.taskId, type: input.type,
            enabled: input.enabled ? 1 : 0, config_json: JSON.stringify(input.config),
            event_config_json: JSON.stringify(input.eventConfig), policy_json: JSON.stringify(input.policy),
            next_run_at: input.nextRunAt?.toISOString() ?? null, created_by_uid: userId});
          if (input.webhookSecret !== undefined) {
            await webhookSecrets.withDatabase(tx).write(webhookSecretRef(teamId, id), input.webhookSecret);
          }
        });
        notifier.publish("task-triggers");
        return triggerById(database, teamId, id, 201, reply);
      } catch (error) {
        return invalidResponse(error, reply);
      }
    });

  /** Vorabprüfung für das UI: meldet Schleifen, ohne den Trigger anzulegen. */
  app.post("/v1/task-triggers/analysis", {schema: {body: CreateTrigger, response: {200: CycleAnalysis, 400: ErrorResponse}}},
    async (request, reply) => {
      try {
        const input = triggerFromRequest(request.body);
        await ensureTask(database, request.workspace.teamId, input.taskId);
        if (input.type !== "event") return {blocked: null, warnings: []};
        return await cycleGuard.checkTrigger(request.workspace.teamId, candidateFrom("preview", input));
      } catch (error) {
        return invalidResponse(error, reply);
      }
    });

  app.put("/v1/task-triggers/:triggerId/enabled", {
    schema: {params: TriggerParams, body: Type.Object({enabled: Type.Boolean()}), response: TriggerResponses},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    if (request.body.enabled) {
      const blocked = await blockedReasonForStored(database, cycleGuard, teamId, request.params.triggerId);
      if (blocked !== null) return reply.code(400).send({error: blocked});
    }
    await database.update(taskTriggers).set({enabled: request.body.enabled ? 1 : 0, updated_at: sql`CURRENT_TIMESTAMP`})
      .where(triggerMatching(database, teamId, request.params.triggerId));
    notifier.publish("task-triggers");
    return triggerById(database, teamId, request.params.triggerId, 200, reply);
  });

  /** Macht die bisherige Webhook-Adresse ungültig, z. B. nach einem Verdacht auf Missbrauch. */
  app.post("/v1/task-triggers/:triggerId/webhook-token", {schema: {params: TriggerParams, response: TriggerResponses}},
    async (request, reply) => {
      const {teamId} = request.workspace;
      const row = await database.select({type: taskTriggers.type, event_config_json: taskTriggers.event_config_json})
        .from(taskTriggers).where(triggerMatching(database, teamId, request.params.triggerId)).get();
      const config = row === undefined || row.type !== "event" ? undefined : eventTriggerConfigFrom(JSON.parse(row.event_config_json));
      if (config?.webhook === undefined) return reply.code(404).send({error: "Webhook-Auslöser nicht gefunden."});
      const next = {...config, webhook: {...webhookConfigFrom(config.webhook), token: generateWebhookToken()}};
      await database.update(taskTriggers).set({event_config_json: JSON.stringify(next), updated_at: sql`CURRENT_TIMESTAMP`})
        .where(triggerMatching(database, teamId, request.params.triggerId));
      notifier.publish("task-triggers");
      return triggerById(database, teamId, request.params.triggerId, 200, reply);
    });

  app.delete("/v1/task-triggers/:triggerId", {schema: {params: TriggerParams}},
    async (request, reply) => {
      const {teamId} = request.workspace;
      await database.transaction(async (tx) => {
        await tx.delete(taskTriggers).where(triggerMatching(tx, teamId, request.params.triggerId));
        await webhookSecrets.withDatabase(tx).delete(webhookSecretRef(teamId, request.params.triggerId));
      });
      notifier.publish("task-triggers");
      return reply.code(204).send();
    });
};

const CycleAnalysis = Type.Object({blocked: Type.Union([Type.String(), Type.Null()]), warnings: Type.Array(Type.String())});

function candidateFrom(id: string, input: TriggerInput) {
  return {id, taskId: input.taskId, config: eventTriggerConfigFrom(input.eventConfig)};
}

async function blockedReason(guard: TriggerCycleGuard, teamId: string, id: string, input: TriggerInput) {
  if (input.type !== "event") return null;
  return (await guard.checkTrigger(teamId, candidateFrom(id, input))).blocked;
}

async function blockedReasonForStored(
  database: RuntimeExecutor, guard: TriggerCycleGuard, teamId: string, triggerId: string,
): Promise<string | null> {
  const row = await database.select({task_id: taskTriggers.task_id, type: taskTriggers.type, event_config_json: taskTriggers.event_config_json})
    .from(taskTriggers).where(triggerMatching(database, teamId, triggerId)).get();
  if (row === undefined || row.type !== "event") return null;
  const config = eventTriggerConfigFrom(JSON.parse(row.event_config_json));
  return (await guard.checkTrigger(teamId, {id: triggerId, taskId: row.task_id, config})).blocked;
}

async function ensureTask(database: RuntimeExecutor, teamId: string, taskId: string): Promise<void> {
  const task = await database.select({id: tasks.id}).from(tasks)
    .where(and(eq(tasks.team_id, teamId), eq(tasks.id, taskId))).get();
  if (task === undefined) throw new LocalTaskTriggerError("Die Aufgabe existiert nicht.");
}

async function triggerById(
  database: RuntimeExecutor, teamId: string, id: string, statusCode: 200 | 201, reply: FastifyReply,
): Promise<FastifyReply> {
  const row = await triggerQuery(database).where(triggerMatching(database, teamId, id)).get();
  return row === undefined
    ? reply.code(404).send({error: "Zeitplan nicht gefunden."})
    : reply.code(statusCode).send(triggerFromRow(row));
}
