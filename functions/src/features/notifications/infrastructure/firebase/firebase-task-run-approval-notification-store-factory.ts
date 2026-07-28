import {type TaskRunApprovalNotificationStore} from "../../domain/repositories/task-run-approval-notification-store.js";
import {FirebasePushNotificationSender} from "./firebase-push-notification-sender.js";
import {
  FirestoreTaskRunApprovalNotificationStore,
} from "./firestore-task-run-approval-notification-store.js";

export function createFirebaseTaskRunApprovalNotificationStore():
TaskRunApprovalNotificationStore {
  return new FirestoreTaskRunApprovalNotificationStore(
    new FirebasePushNotificationSender(),
  );
}
