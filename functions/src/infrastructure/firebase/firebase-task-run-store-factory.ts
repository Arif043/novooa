import {FirestoreActivityStore} from "./firestore-activity-store.js";
import {
  FirestoreTaskRunApprovalNotificationStore,
} from "./firestore-task-run-approval-notification-store.js";
import {FirestoreTaskRunStore} from "./firestore-task-run-store.js";
import {
  FirebasePushNotificationSender,
} from "./firebase-push-notification-sender.js";

export function createFirebaseTaskRunStore(): FirestoreTaskRunStore {
  return new FirestoreTaskRunStore(
    new FirestoreActivityStore(),
    new FirestoreTaskRunApprovalNotificationStore(
      new FirebasePushNotificationSender(),
    ),
  );
}
