import {type ScheduleConfig} from "../entities/schedule.js";

export type TriggerPolicy = {
  ifRunning: string;
};

export type DueScheduleTrigger = {
  id: string;
  teamId: string;
  taskId: string;
  config: ScheduleConfig;
  policy: TriggerPolicy;
};

export type EventTriggerConfig = {
  source: string;
  channelId: string;
  connectorId: string;
  filter: string;
};

export type EventTaskTrigger = {
  id: string;
  teamId: string;
  taskId: string;
  type: string;
  eventConfig: EventTriggerConfig;
};

export interface TaskTriggerStore {
  listDueScheduleTriggers(now: Date, limit: number): Promise<DueScheduleTrigger[]>;
  hasActiveRun(teamId: string, taskId: string): Promise<boolean>;
  advanceScheduleTrigger(
    trigger: DueScheduleTrigger,
    nextRunAt: Date | null,
  ): Promise<void>;
  markScheduleTriggerRan(
    trigger: DueScheduleTrigger,
    now: Date,
    nextRunAt: Date | null,
    runId: string,
  ): Promise<void>;
  listEnabledEventTriggers(teamId: string): Promise<EventTaskTrigger[]>;
  markEventTriggerRan(trigger: EventTaskTrigger, runId: string): Promise<void>;
}
