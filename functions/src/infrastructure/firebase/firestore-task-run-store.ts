import {FieldValue} from "firebase-admin/firestore";
import {UserFacingError} from "genkit";
import {
  type CompletedTaskGraphOutput,
  type WaitingTaskGraphOutput,
} from "../../domain/entities/task.js";
import {textOutputFromResult} from "../../task-runner/node-executor.js";
import {errorDetails} from "../../task-runner/structured-logger.js";
import {
  markTaskRunApprovalNotifications,
  notifyTaskRunApprovalRequired,
} from "../../task-runner/task-run-approval-notifier.js";
import {type ActivityStore} from "../../domain/repositories/activity-store.js";
import {FirestoreActivityStore} from "./firestore-activity-store.js";
import {getDatabase} from "./firestore-db.js";
import {
  approvedDocument,
  rejectedDocument,
  resumeStateFromDocument,
  runStatus,
  serializable,
  successDocument,
} from "./firestore-task-run-documents.js";
import {
  type EnqueueTaskRunInput,
  newTaskRunDocument,
  type ReviewableTaskRun,
  runFromDocument,
  type TaskRunDocument,
  type TaskRunStore,
} from "../../domain/repositories/task-run-store.js";

export class FirestoreTaskRunStore implements TaskRunStore {
  constructor(private readonly activityStore: ActivityStore =
    new FirestoreActivityStore()) {}

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
    await runReference(teamId, run.runId).set(successDocument(output), {
      merge: true,
    });
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
      resumeState: serializable(output.resumeState),
      pausedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    await notifyTaskRunApprovalRequired({teamId, run, output, review});
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
    await markTaskRunApprovalNotifications({teamId, runId, status: "rejected"});
  }

  async approveTaskRun(teamId: string, runId: string, output: string) {
    await runReference(teamId, runId).set(approvedDocument(output), {merge: true});
    await markTaskRunApprovalNotifications({teamId, runId, status: "accepted"});
  }
}

function reviewFieldsFrom(output: WaitingTaskGraphOutput) {
  const result = output.resumeState.nodeResults.find(
    (item) => item.nodeId === output.resumeState.waitingNodeId,
  );
  return {
    instruction: result?.message ?? "Prüfe das Ergebnis und gib es frei.",
    output: result === undefined ? output.finalOutput : textOutputFromResult(result),
  };
}

function assertWaitingRun(data: Record<string, unknown>): void {
  if (data.status === "waitingForApproval") return;
  throw new UserFacingError(
    "FAILED_PRECONDITION",
    "Diese Ausführung wartet nicht auf eine Freigabe.",
  );
}

function runNotFound(): UserFacingError {
  return new UserFacingError("NOT_FOUND", "Ausführung wurde nicht gefunden.");
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
