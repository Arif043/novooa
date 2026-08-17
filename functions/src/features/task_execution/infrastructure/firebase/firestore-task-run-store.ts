import {FieldValue} from "firebase-admin/firestore";
import {
  type CompletedTaskGraphOutput,
  type WaitingTaskGraphOutput,
} from "../../domain/entities/task.js";
import {errorDetails} from "../genkit/runner/structured-logger.js";
import {reviewFieldsFrom} from "../genkit/runner/task-run-review-fields.js";
import {
  invalidReviewState,
  invalidResumeState,
  runNotFound,
} from "../genkit/runner/task-run-store-errors.js";
import {type ActivityStore} from "../../domain/repositories/activity-store.js";
import {
  type TaskRunApprovalNotificationStore,
} from "../../../notifications/domain/repositories/task-run-approval-notification-store.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {
  approvedDocument,
  rejectedDocument,
  resumeStateFromDocument,
  runStatus,
  serializable,
} from "./firestore-task-run-documents.js";
import {type NodeOutputValue} from "../../domain/entities/task.js";
import {
  type EnqueueTaskRunInput,
  newTaskRunDocument,
  type ResumableTaskRun,
  type ReviewableTaskRun,
  runFromDocument,
  type TaskRunDocument,
  type TaskRunStore,
} from "../../domain/repositories/task-run-store.js";

export class FirestoreTaskRunStore implements TaskRunStore {
  constructor(
    private readonly activityStore: ActivityStore,
    private readonly approvalNotifications: TaskRunApprovalNotificationStore,
  ) {}

  async enqueueTaskRun(input: EnqueueTaskRunInput): Promise<TaskRunDocument> {
    const run = newTaskRunDocument(input);
    await runReference(input.teamId, run.runId).set({
      ...run,
      status: "queued",
      input: serializable(input.input ?? {}),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    await this.activityStore.writeTaskActivity(input.teamId, {
      run,
      status: "started",
      input: input.context,
    });
    return run;
  }

  async markRunStarted(teamId: string, runId: string) {
    await runReference(teamId, runId).set(runStatus("running"), {merge: true});
  }

  async loadTaskRun(teamId: string, runId: string): Promise<TaskRunDocument> {
    const snapshot = await runReference(teamId, runId).get();
    if (!snapshot.exists) throw runNotFound();
    return runFromDocument(snapshot.data() ?? {});
  }

  async loadResumableRun(
    teamId: string,
    runId: string,
  ): Promise<ResumableTaskRun> {
    const snapshot = await runReference(teamId, runId).get();
    if (!snapshot.exists) throw runNotFound();
    const data = snapshot.data() ?? {};
    assertQueuedRun(data);
    return {
      run: runFromDocument(data),
      resumeState: resumeStateFromDocument(data),
      responseOutputs: responseOutputsFromDocument(data),
    };
  }

  async markRunSucceeded(
    teamId: string,
    run: TaskRunDocument,
    output: CompletedTaskGraphOutput,
  ) {
    await this.activityStore.writeNodeActivities(teamId, run, output.nodeResults);
    await this.activityStore.writeTaskActivity(teamId, {
      run,
      status: "succeeded",
      output,
    });
    await runReference(teamId, run.runId).delete();
  }

  async markRunWaitingForApproval(
    teamId: string,
    run: TaskRunDocument,
    output: WaitingTaskGraphOutput,
  ) {
    const review = reviewFieldsFrom(output);
    await this.activityStore.writeNodeActivities(teamId, run, output.nodeResults);
    await runReference(teamId, run.runId).set({
      ...runStatus("waitingForApproval"),
      waitingNodeId: output.resumeState.waitingNodeId,
      finalOutput: output.finalOutput,
      reviewInstruction: review.instruction,
      reviewOutput: review.output,
      interaction: review.interaction,
      dialogInput: FieldValue.delete(),
      resumeState: serializable(output.resumeState),
      pausedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    await this.approvalNotifications.notifyApprovalRequired({
      teamId,
      run,
      output,
      review,
    });
  }

  async markRunFailed(teamId: string, run: TaskRunDocument, error: unknown) {
    const details = errorDetails(error);
    await this.activityStore.writeTaskActivity(teamId, {
      run,
      status: "failed",
      message: errorMessage(details),
    });
    await runReference(teamId, run.runId).set({
      ...runStatus("failed"),
      error: details,
    }, {merge: true});
  }

  async loadReviewableRun(
    teamId: string,
    runId: string,
  ): Promise<ReviewableTaskRun> {
    const snapshot = await runReference(teamId, runId).get();
    if (!snapshot.exists) throw runNotFound();
    const data = snapshot.data() ?? {};
    assertWaitingRun(data);
    return {
      run: runFromDocument(data),
      resumeState: resumeStateFromDocument(data),
    };
  }

  async rejectTaskRun(teamId: string, runId: string) {
    await runReference(teamId, runId).set(rejectedDocument(), {merge: true});
    await this.approvalNotifications.markApprovalNotifications({
      teamId,
      runId,
      status: "rejected",
    });
  }

  async approveTaskRun(
    teamId: string,
    runId: string,
    outputs: Record<string, NodeOutputValue>,
  ) {
    await runReference(teamId, runId).set(approvedDocument(outputs), {merge: true});
    await this.approvalNotifications.markApprovalNotifications({
      teamId,
      runId,
      status: "accepted",
    });
  }
}

function assertWaitingRun(data: Record<string, unknown>): void {
  if (data.status === "waitingForApproval") return;
  throw invalidReviewState();
}

function assertQueuedRun(data: Record<string, unknown>): void {
  if (data.status === "queued") return;
  throw invalidResumeState();
}

function errorMessage(details: unknown): string {
  if (isObject(details) && typeof details.message === "string") {
    return details.message;
  }
  return String(details);
}

function runReference(teamId: string, runId: string) {
  return getDatabase().collection("teams").doc(teamId).collection("taskRuns")
    .doc(runId);
}

function isObject(value: unknown): value is {message?: unknown} {
  return typeof value === "object" && value !== null;
}

function responseOutputsFromDocument(
  data: Record<string, unknown>,
): Record<string, NodeOutputValue> {
  if (isObject(data.responseOutputs)) {
    return data.responseOutputs as Record<string, NodeOutputValue>;
  }
  return {text: {type: "string", value: String(data.approvedOutput ?? "")}};
}
