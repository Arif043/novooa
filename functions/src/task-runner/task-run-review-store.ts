import {FirestoreTaskRunStore} from "./stores/firestore-task-run-store.js";
import {type ReviewableTaskRun} from "./stores/task-run-store.js";

export type {ReviewableTaskRun};

const defaultTaskRunStore = new FirestoreTaskRunStore();

export function loadReviewableRun(
  teamId: string,
  runId: string,
): Promise<ReviewableTaskRun> {
  return defaultTaskRunStore.loadReviewableRun(teamId, runId);
}

export function rejectTaskRun(teamId: string, runId: string): Promise<void> {
  return defaultTaskRunStore.rejectTaskRun(teamId, runId);
}

export function approveTaskRun(
  teamId: string,
  runId: string,
  output: string,
): Promise<void> {
  return defaultTaskRunStore.approveTaskRun(teamId, runId, output);
}
