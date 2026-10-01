import {and, eq, getTableColumns, sql} from "drizzle-orm";
import {type FastifyInstance, type FastifyReply} from "fastify";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {tasks, taskTriggers} from "../../../../db/schema.js";
import {type LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {enabledFrom, invalidResponse, LocalTaskTriggerError, triggerFromRequest, triggerFromRow, } from "./local-task-trigger-http-support.js";
export class LocalTaskTriggerHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalTaskTriggerHttpHandler): void {
    http.get("/v1/task-triggers", (request, reply) => current().list(reply));
    http.post("/v1/task-triggers", (request, reply) => current().create(request.body, reply));
    http.put<{
      Params: {
        triggerId: string;
      };
    }>("/v1/task-triggers/:triggerId/enabled", (request, reply) => current().setEnabled(request.params.triggerId, request.body, reply));
    http.delete<{
      Params: {
        triggerId: string;
      };
    }>("/v1/task-triggers/:triggerId", (request, reply) => current().delete(request.params.triggerId, reply));
  }
  constructor(private readonly database: RuntimeExecutor, private readonly teamId: string, private readonly userId: string, private readonly notifier: LocalRuntimeRealtimeNotifier) { }
  private async list(reply: FastifyReply): Promise<FastifyReply> {
    const rows = await triggerQuery(this.database).where(eq(taskTriggers.team_id, this.teamId))
      .orderBy(sql`${taskTriggers.next_run_at} IS NULL`, taskTriggers.next_run_at);
    return reply.code(200).send({ items: rows.map(triggerFromRow) });
  }
  private async create(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const input = triggerFromRequest(body);
      await this.ensureTask(input.taskId);
      const id = randomUUID();
      await this.database.insert(taskTriggers).values({id: id, team_id: this.teamId, task_id: input.taskId, type: input.type, enabled: input.enabled ? 1 : 0, config_json: JSON.stringify(input.config), event_config_json: JSON.stringify(input.eventConfig), policy_json: JSON.stringify(input.policy), next_run_at: input.nextRunAt?.toISOString() ?? null, created_by_uid: this.userId});
      this.notifier.publish("task-triggers");
      return this.byId(id, 201, reply);
    }
    catch (error) {
      return invalidResponse(error, reply);
    }
  }
  private async setEnabled(id: string, body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      await this.database.update(taskTriggers).set({enabled: enabledFrom(body) ? 1 : 0, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskTriggers.team_id, this.teamId), eq(taskTriggers.id, id)));
      this.notifier.publish("task-triggers");
      return this.byId(id, 200, reply);
    }
    catch (error) {
      return invalidResponse(error, reply);
    }
  }
  private async delete(id: string, reply: FastifyReply): Promise<FastifyReply> {
    await this.database.delete(taskTriggers).where(and(eq(taskTriggers.team_id, this.teamId), eq(taskTriggers.id, id)));
    this.notifier.publish("task-triggers");
    return reply.code(204).send();
  }
  private async ensureTask(taskId: string): Promise<void> {
    const task = (await this.database.select({id: tasks.id}).from(tasks).where(and(eq(tasks.team_id, this.teamId), eq(tasks.id, taskId))).get()) ?? null;
    if (task === null)
      throw new LocalTaskTriggerError("Die Aufgabe existiert nicht.");
  }
  private async byId(id: string, statusCode: number, reply: FastifyReply): Promise<FastifyReply> {
    const row = await triggerQuery(this.database).where(and(eq(taskTriggers.team_id, this.teamId), eq(taskTriggers.id, id))).get();
    return row === undefined
      ? reply.code(404).send({ error: "Zeitplan nicht gefunden." }) : reply.code(statusCode).send(triggerFromRow(row));
  }
}
function triggerQuery(database: RuntimeExecutor) {
  return database.select({...getTableColumns(taskTriggers), task_title: tasks.title})
    .from(taskTriggers).innerJoin(tasks, eq(tasks.id, taskTriggers.task_id));
}
