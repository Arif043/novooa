import {FirestoreActivityStore} from "./firestore-activity-store.js";
import {FirestoreTaskRunStore} from "./firestore-task-run-store.js";
import {type TaskRunApprovalNotificationStore} from
  "../../../notifications/domain/repositories/task-run-approval-notification-store.js";

export function createFirebaseTaskRunStore(
  approvalNotifications: TaskRunApprovalNotificationStore,
): FirestoreTaskRunStore {
  return new FirestoreTaskRunStore(
    new FirestoreActivityStore(),
    approvalNotifications,
  );
}
