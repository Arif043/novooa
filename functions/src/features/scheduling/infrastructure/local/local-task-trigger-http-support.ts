import {nextRunAfter, type ScheduleConfig} from "../../domain/usecases/schedule-next-run.js";
import {type FastifyReply} from "fastify";

export type TriggerRow = {
  config_json: string;
  enabled: number;
  event_config_json: string;
  id: string;
  last_run_at: string | null;
  last_run_id: string | null;
  next_run_at: string | null;
  policy_json: string;
  task_id: string;
  task_title: string;
  team_id: string;
  type: string;
};

export type TriggerInput = {
  config: ScheduleConfig | Record<string, never>;
  enabled: boolean;
  eventConfig: Record<string, unknown>;
  nextRunAt: Date | null;
  policy: Record<string, unknown>;
  taskId: string;
  type: "schedule" | "event";
};

export function triggerFromRequest(value: unknown): TriggerInput {
  const input = recordFrom(value);
  const type = stringFrom(input.type, "type");
  if (type === "event") return eventTriggerFrom(input);
  if (type !== "schedule") throw new LocalTaskTriggerError("type ist ungültig.");
  const config = scheduleFrom(input.config);
  const nextRunAt = nextRunAfter(config, new Date());
  if (nextRunAt === null) throw new LocalTaskTriggerError("Der Zeitplan ist ungültig.");
  return {
    taskId: stringFrom(input.taskId, "taskId"), type, config, eventConfig: {},
    policy: policyFrom(input.policy), enabled: input.enabled !== false, nextRunAt,
  };
}

export function triggerFromRow(row: TriggerRow): Record<string, unknown> {
  return {
    id: row.id, teamId: row.team_id, taskId: row.task_id, taskTitle: row.task_title,
    type: row.type, enabled: row.enabled === 1, config: jsonObject(row.config_json),
    eventConfig: jsonObject(row.event_config_json), policy: jsonObject(row.policy_json),
    nextRunAt: isoOrNull(row.next_run_at), lastRunAt: isoOrNull(row.last_run_at), lastRunId: row.last_run_id,
  };
}

export function enabledFrom(value: unknown): boolean {
  const enabled = recordFrom(value).enabled;
  if (typeof enabled !== "boolean") throw new LocalTaskTriggerError("enabled muss boolesch sein.");
  return enabled;
}

export function invalidResponse(error: unknown, reply: FastifyReply): FastifyReply {
  if (error instanceof LocalTaskTriggerError || error instanceof RangeError) {
    return reply.code(400).send({error: error instanceof Error ? error.message : "Ungültiger Zeitplan."});
  }
  throw error;
}

function eventTriggerFrom(input: Record<string, unknown>): TriggerInput {
  return {
    taskId: stringFrom(input.taskId, "taskId"), type: "event", config: {},
    eventConfig: recordFrom(input.eventConfig ?? {}), policy: policyFrom(input.policy),
    enabled: input.enabled !== false, nextRunAt: null,
  };
}

function scheduleFrom(value: unknown): ScheduleConfig {
  const input = recordFrom(value);
  const kind = stringFrom(input.kind, "config.kind");
  if (kind !== "once" && kind !== "daily" && kind !== "weekly") {
    throw new LocalTaskTriggerError("config.kind ist ungültig.");
  }
  return {
    kind, timezone: stringFrom(input.timezone, "config.timezone"), runAt: dateFrom(input.runAt),
    timeOfDay: optionalString(input.timeOfDay), weekdays: numberList(input.weekdays),
    slots: slotList(input.slots),
  };
}

function policyFrom(value: unknown): Record<string, unknown> {
  const input = value === undefined ? {} : recordFrom(value);
  const policy = optionalString(input.ifRunning) ?? "skipIfRunning";
  if (policy !== "skipIfRunning" && policy !== "startParallel") {
    throw new LocalTaskTriggerError("policy.ifRunning ist ungültig.");
  }
  return {ifRunning: policy};
}

function recordFrom(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new LocalTaskTriggerError("Der lokale Zeitplan erwartet ein Objekt.");
}

function stringFrom(value: unknown, name: string): string {
  if (typeof value === "string" && value.trim().length > 0) return value;
  throw new LocalTaskTriggerError(`${name} muss ein nicht leerer String sein.`);
}

function optionalString(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function dateFrom(value: unknown): Date | undefined {
  if (typeof value !== "string") return undefined;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? undefined : date;
}

function numberList(value: unknown): number[] {
  return Array.isArray(value) && value.every(Number.isInteger) ? value as number[] : [];
}

function slotList(value: unknown): Array<{weekday: number; timeOfDay: string}> {
  if (!Array.isArray(value)) return [];
  return value.map(recordFrom).map((slot) => ({weekday: Number(slot.weekday), timeOfDay: optionalString(slot.timeOfDay) ?? ""}));
}

function jsonObject(value: string): Record<string, unknown> {
  try { return recordFrom(JSON.parse(value)); } catch { return {}; }
}

function isoOrNull(value: string | null): string | null {
  return value === null ? null : value.includes("T") ? value : `${value.replace(" ", "T")}Z`;
}

export class LocalTaskTriggerError extends Error {}
