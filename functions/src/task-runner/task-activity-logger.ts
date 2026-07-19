import {
  type CompletedTaskGraphOutput,
  type WaitingTaskGraphOutput,
} from "./task-definition.js";
import {FirestoreTaskRunStore} from "./stores/firestore-task-run-store.js";
import {
  type EnqueueTaskRunInput,
  runFromDocument,
  type TaskRunDocument,
} from "./stores/task-run-store.js";

export {runFromDocument, type TaskRunDocument};

const defaultTaskRunStore = new FirestoreTaskRunStore();

export function enqueueTaskRun(input: EnqueueTaskRunInput) {
  return defaultTaskRunStore.enqueueTaskRun(input);
}

export function markRunStarted(teamId: string, runId: string) {
  return defaultTaskRunStore.markRunStarted(teamId, runId);
}

export function markRunSucceeded(
  teamId: string,
  run: TaskRunDocument,
  output: CompletedTaskGraphOutput,
) {
  return defaultTaskRunStore.markRunSucceeded(teamId, run, output);
}

export function markRunWaitingForApproval(
  teamId: string,
  run: TaskRunDocument,
  output: WaitingTaskGraphOutput,
) {
  return defaultTaskRunStore.markRunWaitingForApproval(teamId, run, output);
}

export function markRunFailed(
  teamId: string,
  run: TaskRunDocument,
  error: unknown,
) {
  return defaultTaskRunStore.markRunFailed(teamId, run, error);
}
