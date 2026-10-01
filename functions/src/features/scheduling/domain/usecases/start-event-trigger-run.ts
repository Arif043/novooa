import {type EventTaskTrigger, type TaskTriggerStore} from "../repositories/task-trigger-store.js";
import {type TaskStore} from "../../../task_execution/domain/repositories/task-store.js";
import {type TaskRunStore} from "../../../task_execution/domain/repositories/task-run-store.js";
import {type TaskRunDispatcher} from "../../../task_execution/domain/repositories/task-run-dispatcher.js";

export type EventTriggerRunPorts = {
  triggerStore: TaskTriggerStore;
  taskStore: TaskStore;
  taskRunStore: TaskRunStore;
  taskRunDispatcher: TaskRunDispatcher;
};

/**
 * Startet die Aufgabe eines passenden Event-Triggers. `context` ist der
 * lesbare Auslösetext, `event` der strukturierte Eingabewert der Aufgabe.
 */
export async function startEventTriggerRun(
  trigger: EventTaskTrigger,
  run: {context: string; event: unknown},
  ports: EventTriggerRunPorts,
): Promise<void> {
  const task = await ports.taskStore.loadTask(trigger.teamId, trigger.taskId);
  const queued = await ports.taskRunStore.enqueueTaskRun({
    teamId: trigger.teamId, task, context: run.context,
    input: {event: run.event}, trigger: {id: trigger.id, type: "event"},
  });
  await ports.taskRunDispatcher.dispatchTaskRun({teamId: trigger.teamId, runId: queued.runId, mode: "start"});
  await ports.triggerStore.markEventTriggerRan(trigger, queued.runId);
}
