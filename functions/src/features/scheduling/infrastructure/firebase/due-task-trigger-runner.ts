import {FirestoreTaskTriggerStore} from "./firestore-task-trigger-store.js";
import {FirestoreTaskStore} from "../../../task_execution/infrastructure/firebase/firestore-task-store.js";
import {FirebaseTaskRunDispatcher} from "../../../task_execution/infrastructure/firebase/firebase-task-run-dispatcher.js";
import {createFirebaseTaskRunApprovalNotificationStore} from "../../../notifications/infrastructure/firebase/firebase-task-run-approval-notification-store-factory.js";
import {createFirebaseTaskRunStore} from "../../../task_execution/infrastructure/firebase/firebase-task-run-store-factory.js";
import {errorDetails, logError, logInfo} from "../../../../shared/logging/logger.js";
import {
  runDueTaskTriggers as runDueTaskTriggerUseCase,
  type DueTaskTriggerRunnerStores,
} from "../../domain/usecases/run-due-task-triggers.js";

const defaultStores: DueTaskTriggerRunnerStores = {
  triggerStore: new FirestoreTaskTriggerStore(),
  taskStore: new FirestoreTaskStore(),
  taskRunStore: createFirebaseTaskRunStore(createFirebaseTaskRunApprovalNotificationStore()),
  taskRunDispatcher: new FirebaseTaskRunDispatcher(),
};

export async function runDueTaskTriggers(
  now = new Date(),
  stores: DueTaskTriggerRunnerStores = defaultStores,
): Promise<void> {
  logInfo("task_trigger.started", {now: now.toISOString()});
  await runDueTaskTriggerUseCase(now, stores, (trigger, error) => {
    logError("task_trigger.failed", {
      triggerId: trigger.id, teamId: trigger.teamId, error: errorDetails(error),
    });
  });
}
