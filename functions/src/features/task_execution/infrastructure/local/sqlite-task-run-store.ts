import {
  type CompletedTaskGraphOutput,
  type NodeOutputValue,
  type TaskResumeState,
  type WaitingTaskGraphOutput,
} from "../../domain/entities/task.js";
import {
  taskResumeStateSchema,
} from "../genkit/runner/task-definition.js";
import {errorDetails} from "../genkit/runner/structured-logger.js";
import {reviewFieldsFrom} from "../genkit/runner/task-run-review-fields.js";
import {
  invalidReviewState,
  invalidResumeState,
  runNotFound,
} from "../genkit/runner/task-run-store-errors.js";
import {type ActivityStore} from "../../domain/repositories/activity-store.js";
import {type TaskRunApprovalNotificationStore} from
  "../../../notifications/domain/repositories/task-run-approval-notification-store.js";
import {
  type EnqueueTaskRunInput,
  newTaskRunDocument,
  type ResumableTaskRun,
  type ReviewableTaskRun,
  type TaskRunDocument,
  type TaskRunStore,
} from "../../domain/repositories/task-run-store.js";
import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";
import {
  approveSql,
  failedSql,
  insertRunSql,
  loadRunSql,
  rejectSql,
  statusSql,
  successSql,
  waitingSql,
} from "./sqlite-task-run-sql.js";

type TaskRunRow = SqlRow & {
  id: string;
  task_id: string;
  task_title: string;
  context: string;
  input_json: string;
  resume_state_json: string | null;
  response_outputs_json: string | null;
  status: string;
};

export class SQLiteTaskRunStore implements TaskRunStore {
  constructor(
    private readonly database: LocalSqlDatabase,
    private readonly activityStore: ActivityStore,
    private readonly approvalNotifications: TaskRunApprovalNotificationStore,
  ) {}

  async enqueueTaskRun(input: EnqueueTaskRunInput): Promise<TaskRunDocument> {
    const run = newTaskRunDocument(input);
    await this.insertRun(input.teamId, run);
    await this.activityStore.writeTaskActivity(input.teamId, {
      run,
      status: "started",
      input: input.context,
    });
    return run;
  }

  async markRunStarted(teamId: string, runId: string) {
    await this.updateStatus(teamId, runId, "running", "started_at");
  }

  async loadTaskRun(teamId: string, runId: string): Promise<TaskRunDocument> {
    return runFromRow(await this.loadRunRow(teamId, runId));
  }

  async loadResumableRun(
    teamId: string,
    runId: string,
  ): Promise<ResumableTaskRun> {
    const row = await this.loadRunRow(teamId, runId);
    if (row.status !== "queued") throw invalidResumeState();
    return {
      run: runFromRow(row),
      resumeState: resumeStateFromRow(row),
      responseOutputs: responseOutputsFromRow(row),
    };
  }

  async markRunSucceeded(
    teamId: string,
    run: TaskRunDocument,
    output: CompletedTaskGraphOutput,
  ) {
    await this.activityStore.writeNodeActivities(teamId, run, output.nodeResults);
    await this.activityStore.writeTaskActivity(teamId, {run, status: "succeeded", output});
    await this.database.run(successSql(), [output.finalOutput, teamId, run.runId]);
  }

  async markRunWaitingForApproval(
    teamId: string,
    run: TaskRunDocument,
    output: WaitingTaskGraphOutput,
  ) {
    const review = reviewFieldsFrom(output);
    await this.activityStore.writeNodeActivities(teamId, run, output.nodeResults);
    await this.database.run(waitingSql(), [
      output.finalOutput,
      output.resumeState.waitingNodeId ?? "",
      review.instruction,
      review.output,
      json(review.interaction),
      json(output.resumeState),
      teamId,
      run.runId,
    ]);
    await this.approvalNotifications.notifyApprovalRequired({teamId, run, output, review});
  }

  async markRunFailed(teamId: string, run: TaskRunDocument, error: unknown) {
    await this.activityStore.writeTaskActivity(teamId, {
      run,
      status: "failed",
      message: errorMessage(error),
    });
    await this.database.run(failedSql(), [json(errorDetails(error)), teamId, run.runId]);
  }

  async loadReviewableRun(
    teamId: string,
    runId: string,
  ): Promise<ReviewableTaskRun> {
    const row = await this.loadRunRow(teamId, runId);
    if (row.status !== "waitingForApproval") throw invalidReviewState();
    return {run: runFromRow(row), resumeState: resumeStateFromRow(row)};
  }

  async rejectTaskRun(teamId: string, runId: string) {
    await this.database.run(rejectSql(), [teamId, runId]);
    await this.approvalNotifications.markApprovalNotifications({teamId, runId, status: "rejected"});
  }

  async approveTaskRun(
    teamId: string,
    runId: string,
    outputs: Record<string, NodeOutputValue>,
  ) {
    await this.database.run(approveSql(), [json(outputs), teamId, runId]);
    await this.approvalNotifications.markApprovalNotifications({teamId, runId, status: "accepted"});
  }

  private async insertRun(teamId: string, run: TaskRunDocument) {
    await this.database.run(insertRunSql(), [
      run.runId,
      teamId,
      run.taskId,
      run.taskTitle,
      "queued",
      run.context,
      json(run.input ?? {}),
      run.source ?? null,
      run.triggerId ?? null,
      run.triggerType ?? null,
    ]);
  }

  private async updateStatus(teamId: string, runId: string, status: string, field: string) {
    await this.database.run(statusSql(field), [status, teamId, runId]);
  }

  private async loadRunRow(teamId: string, runId: string): Promise<TaskRunRow> {
    const row = await this.database.get<TaskRunRow>(loadRunSql(), [teamId, runId]);
    if (row === null) throw runNotFound();
    return row;
  }
}

function runFromRow(row: TaskRunRow): TaskRunDocument {
  return {
    runId: row.id,
    taskId: row.task_id,
    taskTitle: row.task_title,
    context: row.context,
    input: jsonRecord(row.input_json),
  };
}

function resumeStateFromRow(row: TaskRunRow) {
  return taskResumeStateSchema.parse(
    jsonRecord(row.resume_state_json ?? "{}"),
  ) as TaskResumeState;
}

function errorMessage(error: unknown): string {
  const details = errorDetails(error);
  if (isRecord(details) && typeof details.message === "string") return details.message;
  return String(details);
}

function json(value: unknown): string {
  return JSON.stringify(value);
}

function jsonRecord(value: string): Record<string, unknown> {
  const parsed: unknown = JSON.parse(value);
  return isRecord(parsed) ? parsed : {};
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function responseOutputsFromRow(
  row: TaskRunRow,
): Record<string, NodeOutputValue> {
  if (row.response_outputs_json === null) return {};
  return jsonRecord(row.response_outputs_json) as Record<string, NodeOutputValue>;
}
