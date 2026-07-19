import {FirestoreTaskRunStore} from "../task-runner/stores/firestore-task-run-store.js";
import {FirestoreTaskStore} from "../task-runner/stores/firestore-task-store.js";
import {type TaskRunStore} from "../task-runner/stores/task-run-store.js";
import {type TaskStore} from "../task-runner/stores/task-store.js";
import {errorDetails, logError, logInfo} from "../task-runner/structured-logger.js";
import {FirestoreTaskTriggerStore} from "../triggers/firestore-task-trigger-store.js";
import {
  type DueScheduleTrigger,
  type TaskTriggerStore,
} from "../triggers/task-trigger-store.js";
import {nextRunAfter, type ScheduleConfig} from "./schedule-next-run.js";

type DueTriggerRunnerStores = {
  triggerStore: TaskTriggerStore;
  taskStore: TaskStore;
  taskRunStore: TaskRunStore;
};

const defaultStores: DueTriggerRunnerStores = {
  triggerStore: new FirestoreTaskTriggerStore(),
  taskStore: new FirestoreTaskStore(),
  taskRunStore: new FirestoreTaskRunStore(),
};

export async function runDueTaskTriggers(
  now = new Date(),
  stores: DueTriggerRunnerStores = defaultStores,
): Promise<void> {
  logInfo("task_trigger.started", {now: now.toISOString()});
  const dueTriggers = await stores.triggerStore.listDueScheduleTriggers(now, 50);
  for (const trigger of dueTriggers) {
    await runTrigger(trigger, now, stores);
  }
}

async function runTrigger(
  trigger: DueScheduleTrigger,
  now: Date,
  stores: DueTriggerRunnerStores,
): Promise<void> {
  try {
    if (await shouldSkip(trigger, stores.triggerStore)) {
      await advanceTrigger(trigger, now, stores.triggerStore);
      return;
    }
    const task = await stores.taskStore.loadTask(trigger.teamId, trigger.taskId);
    const run = await stores.taskRunStore.enqueueTaskRun({
      teamId: trigger.teamId,
      task,
      context: "",
      trigger: {id: trigger.id, type: "schedule"},
    });
    await markTriggerRan(trigger, now, run.runId, stores.triggerStore);
  } catch (error) {
    logError("task_trigger.failed", {
      triggerId: trigger.id,
      teamId: trigger.teamId,
      error: errorDetails(error),
    });
  }
}

async function shouldSkip(
  trigger: DueScheduleTrigger,
  store: TaskTriggerStore,
): Promise<boolean> {
  if (trigger.policy.ifRunning !== "skipIfRunning") return false;
  return store.hasActiveRun(trigger.teamId, trigger.taskId);
}

async function markTriggerRan(
  trigger: DueScheduleTrigger,
  now: Date,
  runId: string,
  store: TaskTriggerStore,
) {
  const nextRunAt = nextRunAfterRun(trigger.config, now);
  await store.markScheduleTriggerRan(trigger, now, nextRunAt, runId);
}

async function advanceTrigger(
  trigger: DueScheduleTrigger,
  now: Date,
  store: TaskTriggerStore,
) {
  await store.advanceScheduleTrigger(trigger, nextRunAfterRun(trigger.config, now));
}

function nextRunAfterRun(config: ScheduleConfig, now: Date): Date | null {
  return nextRunAfter(config, new Date(now.getTime() + 1000));
}
