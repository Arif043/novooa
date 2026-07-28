import {type ScheduleConfig} from "../../domain/usecases/schedule-next-run.js";
import {
  type DueScheduleTrigger,
  type EventTaskTrigger,
  type TaskTriggerStore,
} from "../../domain/repositories/task-trigger-store.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";

type ScheduleTriggerRow = SqlRow & {
  id: string;
  team_id: string;
  task_id: string;
  config_json: string;
  policy_json: string;
};

type EventTriggerRow = ScheduleTriggerRow & {
  type: string;
  event_config_json: string;
};

export class SQLiteTaskTriggerStore implements TaskTriggerStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  async listDueScheduleTriggers(now: Date, limit: number) {
    const rows = await this.database.all<ScheduleTriggerRow>(dueSql(), [
      now.toISOString(),
      limit,
    ]);
    return rows.map(scheduleTriggerFromRow);
  }

  async hasActiveRun(teamId: string, taskId: string): Promise<boolean> {
    const row = await this.database.get<SqlRow>(activeRunSql(), [teamId, taskId]);
    return row !== null;
  }

  async advanceScheduleTrigger(trigger: DueScheduleTrigger, nextRunAt: Date | null) {
    await this.database.run(advanceSql(), [
      enabledValue(nextRunAt),
      dateOrNull(nextRunAt),
      trigger.teamId,
      trigger.id,
    ]);
  }

  async markScheduleTriggerRan(
    trigger: DueScheduleTrigger,
    now: Date,
    nextRunAt: Date | null,
    runId: string,
  ) {
    await this.database.run(ranSql(), [
      enabledValue(nextRunAt),
      dateOrNull(nextRunAt),
      now.toISOString(),
      runId,
      trigger.teamId,
      trigger.id,
    ]);
  }

  async listEnabledEventTriggers(teamId: string): Promise<EventTaskTrigger[]> {
    const rows = await this.database.all<EventTriggerRow>(eventsSql(), [teamId]);
    return rows.map(eventTriggerFromRow);
  }

  async markEventTriggerRan(trigger: EventTaskTrigger, runId: string) {
    await this.database.run(eventRanSql(), [runId, trigger.teamId, trigger.id]);
  }
}

function scheduleTriggerFromRow(row: ScheduleTriggerRow): DueScheduleTrigger {
  return {
    id: row.id,
    teamId: row.team_id,
    taskId: row.task_id,
    config: scheduleConfigFromJson(row.config_json),
    policy: {ifRunning: stringFrom(jsonObject(row.policy_json).ifRunning, "skipIfRunning")},
  };
}

function eventTriggerFromRow(row: EventTriggerRow): EventTaskTrigger {
  const eventConfig = jsonObject(row.event_config_json);
  return {
    id: row.id,
    teamId: row.team_id,
    taskId: row.task_id,
    type: row.type,
    eventConfig: {
      source: stringFrom(eventConfig.source, ""),
      channelId: stringFrom(eventConfig.channelId, ""),
      filter: stringFrom(eventConfig.filter, ""),
    },
  };
}

function scheduleConfigFromJson(value: string): ScheduleConfig {
  const data = jsonObject(value);
  return {
    kind: scheduleKindFrom(data.kind),
    timezone: stringFrom(data.timezone, "Europe/Berlin"),
    runAt: dateFrom(data.runAt),
    timeOfDay: optionalStringFrom(data.timeOfDay),
    weekdays: numberListFrom(data.weekdays),
    slots: Array.isArray(data.slots) ? data.slots.map(slotFrom) : [],
  };
}

function slotFrom(value: unknown) {
  const data = isRecord(value) ? value : {};
  return {weekday: Number(data.weekday ?? 0), timeOfDay: stringFrom(data.timeOfDay, "")};
}

function dueSql() {
  return `SELECT id, team_id, task_id, config_json, policy_json FROM task_triggers
    WHERE enabled = 1 AND next_run_at IS NOT NULL AND next_run_at <= ?
    ORDER BY next_run_at ASC LIMIT ?`;
}

function activeRunSql() {
  return `SELECT id FROM task_runs WHERE team_id = ? AND task_id = ?
    AND status IN ('queued', 'running', 'waitingForApproval') LIMIT 1`;
}

function advanceSql() {
  return `UPDATE task_triggers SET enabled = ?, next_run_at = ?,
    updated_at = CURRENT_TIMESTAMP WHERE team_id = ? AND id = ?`;
}

function ranSql() {
  return `UPDATE task_triggers SET enabled = ?, next_run_at = ?, last_run_at = ?,
    last_run_id = ?, updated_at = CURRENT_TIMESTAMP WHERE team_id = ? AND id = ?`;
}

function eventsSql() {
  return `SELECT id, team_id, task_id, type, config_json, policy_json,
    event_config_json FROM task_triggers WHERE team_id = ? AND enabled = 1`;
}

function eventRanSql() {
  return `UPDATE task_triggers SET last_run_id = ?, last_run_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP WHERE team_id = ? AND id = ?`;
}

function scheduleKindFrom(value: unknown): ScheduleConfig["kind"] {
  if (value === "once" || value === "daily" || value === "weekly") return value;
  return "daily";
}

function dateOrNull(value: Date | null) {
  return value?.toISOString() ?? null;
}

function enabledValue(nextRunAt: Date | null) {
  return nextRunAt === null ? 0 : 1;
}

function dateFrom(value: unknown): Date | undefined {
  if (typeof value !== "string" || value.trim().length === 0) return undefined;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? undefined : date;
}

function optionalStringFrom(value: unknown): string | undefined {
  return typeof value === "string" ? value : undefined;
}

function stringFrom(value: unknown, fallback: string): string {
  return typeof value === "string" ? value : fallback;
}

function numberListFrom(value: unknown): number[] {
  if (!Array.isArray(value)) return [];
  return value.map(Number);
}

function jsonObject(value: string): Record<string, unknown> {
  const parsed: unknown = JSON.parse(value);
  return isRecord(parsed) ? parsed : {};
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
