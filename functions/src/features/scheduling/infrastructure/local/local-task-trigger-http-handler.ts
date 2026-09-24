import {randomUUID} from "node:crypto";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";
import {
  enabledFrom,
  enabledTriggerIdFrom,
  invalidResponse,
  LocalTaskTriggerError,
  pathFrom,
  triggerFromRequest,
  triggerFromRow,
  triggerIdFrom,
  type TriggerRow,
} from "./local-task-trigger-http-support.js";
import {type LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";

export class LocalTaskTriggerHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly database: LocalSqlDatabase,
    private readonly teamId: string,
    private readonly userId: string,
    private readonly notifier: LocalRuntimeRealtimeNotifier,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    const path = pathFrom(request.url);
    if (request.method === "GET" && path === "/v1/task-triggers") return this.list();
    if (request.method === "POST" && path === "/v1/task-triggers") return this.create(request.body);
    const enabledId = enabledTriggerIdFrom(path);
    if (request.method === "PUT" && enabledId !== null) return this.setEnabled(enabledId, request.body);
    const triggerId = triggerIdFrom(path);
    if (request.method === "DELETE" && triggerId !== null) return this.delete(triggerId);
    return null;
  }

  private async list(): Promise<LocalRuntimeResponse> {
    const rows = await this.database.all<TriggerRow>(listSql(), [this.teamId]);
    return {body: {items: rows.map(triggerFromRow)}, statusCode: 200};
  }

  private async create(body: unknown): Promise<LocalRuntimeResponse> {
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
      return this.byId(id, 201);
    } catch (error) {
      return invalidResponse(error);
    }
  }

  private async setEnabled(id: string, body: unknown): Promise<LocalRuntimeResponse> {
    try {
      await this.database.run(updateEnabledSql(), [enabledFrom(body) ? 1 : 0, this.teamId, id]);
      this.notifier.publish("task-triggers");
      return this.byId(id, 200);
    } catch (error) {
      return invalidResponse(error);
    }
  }

  private async delete(id: string): Promise<LocalRuntimeResponse> {
    await this.database.run("DELETE FROM task_triggers WHERE team_id = ? AND id = ?", [this.teamId, id]);
    this.notifier.publish("task-triggers");
    return {body: {}, statusCode: 204};
  }

  private async ensureTask(taskId: string): Promise<void> {
    const task = await this.database.get<SqlRow>("SELECT id FROM tasks WHERE team_id = ? AND id = ?", [this.teamId, taskId]);
    if (task === null) throw new LocalTaskTriggerError("Die Aufgabe existiert nicht.");
  }

  private async byId(id: string, statusCode: number): Promise<LocalRuntimeResponse> {
    const row = await this.database.get<TriggerRow>(byIdSql(), [this.teamId, id]);
    return row === null
      ? {body: {error: "Zeitplan nicht gefunden."}, statusCode: 404}
      : {body: triggerFromRow(row), statusCode};
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
