import {type TaskRunDispatcher} from "../../../task_execution/domain/repositories/task-run-dispatcher.js";
import {type TaskRunStore} from "../../../task_execution/domain/repositories/task-run-store.js";
import {type TaskStore} from "../../../task_execution/domain/repositories/task-store.js";
import {type DueScheduleTrigger, type TaskTriggerStore} from "../repositories/task-trigger-store.js";
import {nextRunAfter} from "./schedule-next-run.js";

export type DueTaskTriggerRunnerStores = {
  taskRunDispatcher: TaskRunDispatcher;
  taskRunStore: TaskRunStore;
  taskStore: TaskStore;
  triggerStore: TaskTriggerStore;
};

export async function runDueTaskTriggers(
  now: Date,
  stores: DueTaskTriggerRunnerStores,
  onFailure: (trigger: DueScheduleTrigger, error: unknown) => void = () => undefined,
): Promise<void> {
  const triggers = await stores.triggerStore.listDueScheduleTriggers(now, 50);
  for (const trigger of triggers) await runTrigger(trigger, now, stores, onFailure);
}

async function runTrigger(
  trigger: DueScheduleTrigger,
  now: Date,
  stores: DueTaskTriggerRunnerStores,
  onFailure: (trigger: DueScheduleTrigger, error: unknown) => void,
): Promise<void> {
  try {
    if (await shouldSkip(trigger, stores.triggerStore)) {
      await stores.triggerStore.advanceScheduleTrigger(trigger, nextRunAfterRun(trigger, now));
      return;
    }
    const task = await stores.taskStore.loadTask(trigger.teamId, trigger.taskId);
    const run = await stores.taskRunStore.enqueueTaskRun({
      teamId: trigger.teamId, task, context: "", trigger: {id: trigger.id, type: "schedule"},
    });
    await stores.taskRunDispatcher.dispatchTaskRun({
      teamId: trigger.teamId, runId: run.runId, mode: "start",
    });
    await stores.triggerStore.markScheduleTriggerRan(
      trigger, now, nextRunAfterRun(trigger, now), run.runId,
    );
  } catch (error) {
    onFailure(trigger, error);
  }
}

async function shouldSkip(trigger: DueScheduleTrigger, store: TaskTriggerStore): Promise<boolean> {
  return trigger.policy.ifRunning === "skipIfRunning" &&
    await store.hasActiveRun(trigger.teamId, trigger.taskId);
}

function nextRunAfterRun(trigger: DueScheduleTrigger, now: Date): Date | null {
  return nextRunAfter(trigger.config, new Date(now.getTime() + 1000));
}
