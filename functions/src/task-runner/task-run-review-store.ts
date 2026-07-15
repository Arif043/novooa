import {getApps, initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  getFirestore,
  type DocumentData,
} from "firebase-admin/firestore";
import {UserFacingError} from "genkit";
import {
  taskResumeStateSchema,
  type TaskResumeState,
} from "./task-definition.js";
import {
  runFromDocument,
  type TaskRunDocument,
} from "./task-activity-logger.js";
import {
  markTaskRunApprovalNotifications,
} from "./task-run-approval-notifier.js";

export type ReviewableTaskRun = {
  run: TaskRunDocument;
  resumeState: TaskResumeState;
};

export async function loadReviewableRun(
  teamId: string,
  runId: string,
): Promise<ReviewableTaskRun> {
  const snapshot = await runReference(teamId, runId).get();
  if (!snapshot.exists) {
    throw new UserFacingError("NOT_FOUND", "Ausführung wurde nicht gefunden.");
  }
  const data = snapshot.data() ?? {};
  assertWaitingRun(data);
  return {
    run: runFromDocument(data),
    resumeState: taskResumeStateSchema.parse(data.resumeState),
  };
}

export async function rejectTaskRun(
  teamId: string,
  runId: string,
): Promise<void> {
  await runReference(teamId, runId).set({
    status: "rejected",
    updatedAt: FieldValue.serverTimestamp(),
    rejectedAt: FieldValue.serverTimestamp(),
    waitingNodeId: FieldValue.delete(),
    finalOutput: FieldValue.delete(),
    nodeResults: FieldValue.delete(),
    resumeState: FieldValue.delete(),
    reviewInstruction: FieldValue.delete(),
    reviewOutput: FieldValue.delete(),
    pausedAt: FieldValue.delete(),
  }, {merge: true});
  await markTaskRunApprovalNotifications({teamId, runId, status: "rejected"});
}

export async function approveTaskRun(
  teamId: string,
  runId: string,
  output: string,
): Promise<void> {
  await runReference(teamId, runId).set({
    status: "queued",
    approvedOutput: output,
    updatedAt: FieldValue.serverTimestamp(),
    waitingNodeId: FieldValue.delete(),
    reviewInstruction: FieldValue.delete(),
    reviewOutput: FieldValue.delete(),
    pausedAt: FieldValue.delete(),
  }, {merge: true});
  await markTaskRunApprovalNotifications({teamId, runId, status: "accepted"});
}

function assertWaitingRun(data: DocumentData): void {
  if (data.status === "waitingForApproval") return;
  throw new UserFacingError(
    "FAILED_PRECONDITION",
    "Diese Ausführung wartet nicht auf eine Freigabe.",
  );
}

function runReference(teamId: string, runId: string) {
  return getDatabase()
    .collection("teams")
    .doc(teamId)
    .collection("taskRuns")
    .doc(runId);
}

function getDatabase() {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}
