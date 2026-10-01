import {and, eq, inArray, isNotNull, lte, sql} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {taskRuns, taskTriggers} from "../../../../db/schema.js";
import {
  type DueScheduleTrigger,
  type EventTaskTrigger,
  type TaskTriggerStore,
} from "../../domain/repositories/task-trigger-store.js";
import {type ScheduleConfig} from "../../domain/usecases/schedule-next-run.js";

type ScheduleTriggerRow = {
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
  constructor(private readonly database: RuntimeExecutor) {}

  async listDueScheduleTriggers(now: Date, limit: number) {
    const rows = await this.database.select({id: taskTriggers.id, team_id: taskTriggers.team_id, task_id: taskTriggers.task_id, config_json: taskTriggers.config_json, policy_json: taskTriggers.policy_json})
      .from(taskTriggers).where(and(eq(taskTriggers.enabled, 1), isNotNull(taskTriggers.next_run_at), lte(taskTriggers.next_run_at, now.toISOString())))
      .orderBy(taskTriggers.next_run_at).limit(limit);
    return rows.map(scheduleTriggerFromRow);
  }

  async hasActiveRun(teamId: string, taskId: string): Promise<boolean> {
    const row = await this.database.select({id: taskRuns.id}).from(taskRuns)
      .where(and(eq(taskRuns.team_id, teamId), eq(taskRuns.task_id, taskId), inArray(taskRuns.status, ["queued", "running", "waitingForApproval"])))
      .limit(1).get();
    return row !== undefined;
  }

  async advanceScheduleTrigger(trigger: DueScheduleTrigger, nextRunAt: Date | null) {
    await this.database.update(taskTriggers).set({enabled: enabledValue(nextRunAt), next_run_at: dateOrNull(nextRunAt), updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskTriggers.team_id, trigger.teamId), eq(taskTriggers.id, trigger.id)));
  }

  async markScheduleTriggerRan(
    trigger: DueScheduleTrigger,
    now: Date,
    nextRunAt: Date | null,
    runId: string,
  ) {
    await this.database.update(taskTriggers).set({enabled: enabledValue(nextRunAt), next_run_at: dateOrNull(nextRunAt), last_run_at: now.toISOString(), last_run_id: runId, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskTriggers.team_id, trigger.teamId), eq(taskTriggers.id, trigger.id)));
  }

  async listEnabledEventTriggers(teamId: string): Promise<EventTaskTrigger[]> {
    const rows = await this.database.select({id: taskTriggers.id, team_id: taskTriggers.team_id, task_id: taskTriggers.task_id, type: taskTriggers.type, config_json: taskTriggers.config_json, policy_json: taskTriggers.policy_json, event_config_json: taskTriggers.event_config_json}).from(taskTriggers).where(and(eq(taskTriggers.team_id, teamId), eq(taskTriggers.enabled, 1)));
    return rows.map(eventTriggerFromRow);
  }

  async markEventTriggerRan(trigger: EventTaskTrigger, runId: string) {
    await this.database.update(taskTriggers).set({last_run_id: runId, last_run_at: sql`CURRENT_TIMESTAMP`, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskTriggers.team_id, trigger.teamId), eq(taskTriggers.id, trigger.id)));
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
      connectorId: stringFrom(eventConfig.connectorId, ""),
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
