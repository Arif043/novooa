import { type FastifyInstance, type FastifyReply } from "fastify";
import { randomUUID } from "node:crypto";
import { type LocalSqlDatabase, type SqlRow } from "../../../../shared/local/local-sql-database.js";
import { enabledFrom, invalidResponse, LocalTaskTriggerError, triggerFromRequest, triggerFromRow, type TriggerRow, } from "./local-task-trigger-http-support.js";
import { type LocalRuntimeRealtimeNotifier } from "../../../../shared/local/local-runtime-realtime-notifier.js";
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
  constructor(private readonly database: LocalSqlDatabase, private readonly teamId: string, private readonly userId: string, private readonly notifier: LocalRuntimeRealtimeNotifier) { }
  private async list(reply: FastifyReply): Promise<FastifyReply> {
    const rows = await this.database.all<TriggerRow>(listSql(), [this.teamId]);
    return reply.code(200).send({ items: rows.map(triggerFromRow) });
  }
  private async create(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      const input = triggerFromRequest(body);
      await this.ensureTask(input.taskId);
      const id = randomUUID();
      await this.database.run(insertSql(), [
        id, this.teamId, input.taskId, input.type, input.enabled ? 1 : 0,
        JSON.stringify(input.config), JSON.stringify(input.eventConfig), JSON.stringify(input.policy),
        input.nextRunAt?.toISOString() ?? null, this.userId,
      ]);
      this.notifier.publish("task-triggers");
      return this.byId(id, 201, reply);
    }
    catch (error) {
      return invalidResponse(error, reply);
    }
  }
  private async setEnabled(id: string, body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    try {
      await this.database.run(updateEnabledSql(), [enabledFrom(body) ? 1 : 0, this.teamId, id]);
      this.notifier.publish("task-triggers");
      return this.byId(id, 200, reply);
    }
    catch (error) {
      return invalidResponse(error, reply);
    }
  }
  private async delete(id: string, reply: FastifyReply): Promise<FastifyReply> {
    await this.database.run("DELETE FROM task_triggers WHERE team_id = ? AND id = ?", [this.teamId, id]);
    this.notifier.publish("task-triggers");
    return reply.code(204).send();
  }
  private async ensureTask(taskId: string): Promise<void> {
    const task = await this.database.get<SqlRow>("SELECT id FROM tasks WHERE team_id = ? AND id = ?", [this.teamId, taskId]);
    if (task === null)
      throw new LocalTaskTriggerError("Die Aufgabe existiert nicht.");
  }
  private async byId(id: string, statusCode: number, reply: FastifyReply): Promise<FastifyReply> {
    const row = await this.database.get<TriggerRow>(byIdSql(), [this.teamId, id]);
    return row === null
      ? reply.code(404).send({ error: "Zeitplan nicht gefunden." }) : reply.code(statusCode).send(triggerFromRow(row));
  }
}
function selectSql(): string {
  return `SELECT triggers.id, triggers.team_id, triggers.task_id, tasks.title AS task_title,
 triggers.type, triggers.enabled, triggers.config_json, triggers.event_config_json,
 triggers.policy_json, triggers.next_run_at, triggers.last_run_at, triggers.last_run_id
 FROM task_triggers AS triggers JOIN tasks ON tasks.id = triggers.task_id`;
}
function listSql(): string {
  return `${selectSql()} WHERE triggers.team_id = ? ORDER BY triggers.next_run_at IS NULL, triggers.next_run_at`;
}
function byIdSql(): string {
  return `${selectSql()} WHERE triggers.team_id = ? AND triggers.id = ?`;
}
function insertSql(): string {
  return `INSERT INTO task_triggers(id, team_id, task_id, type, enabled, config_json,
 event_config_json, policy_json, next_run_at, created_by_uid)
 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
}
function updateEnabledSql(): string {
  return "UPDATE task_triggers SET enabled = ?, updated_at = CURRENT_TIMESTAMP WHERE team_id = ? AND id = ?";
}
