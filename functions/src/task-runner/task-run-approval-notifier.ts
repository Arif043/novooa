import {getApps, initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {type WaitingTaskGraphOutput} from "./task-definition.js";
import {type TaskRunDocument} from "./task-activity-logger.js";

export type TaskRunApprovalReview = {
  instruction: string;
  output: string;
};

export async function notifyTaskRunApprovalRequired(input: {
  teamId: string;
  run: TaskRunDocument;
  output: WaitingTaskGraphOutput;
  review: TaskRunApprovalReview;
}) {
  const members = await membersFor(input.teamId);
  const batch = getDatabase().batch();
  for (const member of members.docs) {
    batch.set(
      notificationReference(member.id, input.run.runId),
      approvalNotificationDocument(input),
    );
  }
  await batch.commit();
}

export async function markTaskRunApprovalNotifications(input: {
  teamId: string;
  runId: string;
  status: "accepted" | "rejected";
}) {
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

function approvalNotificationDocument(input: {
  teamId: string;
  run: TaskRunDocument;
  output: WaitingTaskGraphOutput;
  review: TaskRunApprovalReview;
}) {
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

function actionedDocument(status: "accepted" | "rejected") {
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

function getDatabase() {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}
