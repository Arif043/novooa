import {getFunctions} from "firebase-admin/functions";
import {
  type TaskRunDispatcher,
  type TaskRunDispatchInput,
} from "../../domain/repositories/task-run-dispatcher.js";
import {initializeAdminApp} from "./firestore-db.js";

const queueFunction = "locations/europe-west3/functions/runTaskRunTask";

export class FirebaseTaskRunDispatcher implements TaskRunDispatcher {
  async dispatchTaskRun(input: TaskRunDispatchInput): Promise<void> {
    initializeAdminApp();
    await getFunctions().taskQueue(queueFunction).enqueue(input, {
      id: taskIdFrom(input),
      dispatchDeadlineSeconds: 1800,
    });
  }
}

function taskIdFrom(input: TaskRunDispatchInput): string {
  return `${input.mode}-${input.runId}`;
}
