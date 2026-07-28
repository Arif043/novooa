import {FieldValue} from "firebase-admin/firestore";
import {
  type ApprovalNotificationInput,
  type ApprovalNotificationStatus,
  type MarkApprovalNotificationInput,
  type TaskRunApprovalNotificationStore,
} from "../../domain/repositories/task-run-approval-notification-store.js";
import {
  type PushNotification,
  FirebasePushNotificationSender,
} from "./firebase-push-notification-sender.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";

export class FirestoreTaskRunApprovalNotificationStore
implements TaskRunApprovalNotificationStore {
  constructor(
    private readonly pushNotifications: FirebasePushNotificationSender,
  ) {}

  async notifyApprovalRequired(input: ApprovalNotificationInput) {
    const members = await membersFor(input.teamId);
    const batch = getDatabase().batch();
    for (const member of members.docs) {
      batch.set(
        notificationReference(member.id, input.run.runId),
        approvalNotificationDocument(input),
      );
    }
    await batch.commit();
    await Promise.all(members.docs.map((member) =>
      this.pushNotifications.sendToUser(member.id, approvalPushNotification(input)),
    ));
  }

  async markApprovalNotifications(input: MarkApprovalNotificationInput) {
    const members = await membersFor(input.teamId);
    const batch = getDatabase().batch();
    for (const member of members.docs) {
      batch.set(
        notificationReference(member.id, input.runId),
        actionedDocument(input.status),
        {merge: true},
      );
    }
    await batch.commit();
  }
}

function approvalPushNotification(
  input: ApprovalNotificationInput,
): PushNotification {
  return {
    title: "Freigabe erforderlich",
    body: `"${input.run.taskTitle}" wartet auf deine Prüfung.`,
    data: {
      type: "taskRunApproval",
      teamId: input.teamId,
      runId: input.run.runId,
      taskId: input.run.taskId,
    },
  };
}

function approvalNotificationDocument(input: ApprovalNotificationInput) {
  return {
    type: "taskRunApproval",
    status: "pending",
    title: "Freigabe erforderlich",
    message: `"${input.run.taskTitle}" wartet auf deine Prüfung.`,
    teamId: input.teamId,
    runId: input.run.runId,
    taskId: input.run.taskId,
    taskTitle: input.run.taskTitle,
    waitingNodeId: input.output.resumeState.waitingNodeId,
    finalOutput: input.output.finalOutput,
    reviewInstruction: input.review.instruction,
    reviewOutput: input.review.output,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function actionedDocument(status: ApprovalNotificationStatus) {
  return {
    status,
    updatedAt: FieldValue.serverTimestamp(),
    actionedAt: FieldValue.serverTimestamp(),
  };
}

function notificationReference(uid: string, runId: string) {
  return getDatabase()
    .collection("users")
    .doc(uid)
    .collection("notifications")
    .doc(approvalNotificationId(runId));
}

function membersFor(teamId: string) {
  return getDatabase()
    .collection("teams")
    .doc(teamId)
    .collection("members")
    .get();
}

function approvalNotificationId(runId: string) {
  return `taskRunApproval_${runId}`;
}
