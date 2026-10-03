import {and, eq, sql} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {type TaskRuns, taskRuns} from "../../../../db/schema.js";
import {recordNodeExecutionFailure} from "../../domain/services/record-node-execution-failure.js";
import {type NodeExecutionFailure} from "../../domain/entities/node-execution-failure.js";
import {type TaskRunApprovalNotificationStore} from "../../../notifications/domain/repositories/task-run-approval-notification-store.js";
import {
  type CompletedTaskGraphOutput,
  type NodeOutputValue,
  type TaskResumeState,
  type WaitingTaskGraphOutput,
} from "../../domain/entities/task.js";
import {type ActivityStore} from "../../domain/repositories/activity-store.js";
import {
  type EnqueueTaskRunInput,
  newTaskRunDocument,
  type ResumableTaskRun,
  type ReviewableTaskRun,
  type TaskRunDocument,
  type TaskRunStore,
} from "../../domain/repositories/task-run-store.js";
import {errorDetails} from "../genkit/runner/structured-logger.js";
import {
  taskResumeStateSchema,
} from "../genkit/runner/task-definition.js";
import {reviewFieldsFrom} from "../genkit/runner/task-run-review-fields.js";
import {
  invalidResumeState,
  invalidReviewState,
  runNotFound,
} from "../genkit/runner/task-run-store-errors.js";

type TaskRunRow = Pick<TaskRuns, "id" | "task_id" | "task_title" | "context" | "input_json" | "resume_state_json" | "response_outputs_json" | "status">;

export class SQLiteTaskRunStore implements TaskRunStore {
  constructor(
    private readonly database: RuntimeExecutor,
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
    await this.updateStatus(teamId, runId, "running");
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
    await this.database.update(taskRuns).set({status: "succeeded", final_output: output.finalOutput, completed_at: sql`CURRENT_TIMESTAMP`, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskRuns.team_id, teamId), eq(taskRuns.id, run.runId)));
  }

  async markRunWaitingForApproval(
    teamId: string,
    run: TaskRunDocument,
    output: WaitingTaskGraphOutput,
  ) {
    const review = reviewFieldsFrom(output);
    await this.activityStore.writeNodeActivities(teamId, run, output.nodeResults);
    await this.database.update(taskRuns).set({status: "waitingForApproval", final_output: output.finalOutput, waiting_node_id: output.resumeState.waitingNodeId ?? "", review_instruction: review.instruction, review_output: review.output, interaction_json: json(review.interaction), resume_state_json: json(output.resumeState), paused_at: sql`CURRENT_TIMESTAMP`, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskRuns.team_id, teamId), eq(taskRuns.id, run.runId)));
    await this.approvalNotifications.notifyApprovalRequired({teamId, run, output, review});
  }

  async markRunFailed(
    teamId: string,
    run: TaskRunDocument,
    error: unknown,
    failure?: NodeExecutionFailure,
  ) {
    await recordNodeExecutionFailure(this.activityStore, teamId, run, failure);
    await this.activityStore.writeTaskActivity(teamId, {
      run,
      status: "failed",
      message: errorMessage(error),
    });
    await this.database.update(taskRuns).set({status: "failed", error_json: json(errorDetails(error)), completed_at: sql`CURRENT_TIMESTAMP`, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskRuns.team_id, teamId), eq(taskRuns.id, run.runId)));
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
    await this.database.update(taskRuns).set({status: "rejected", reviewed_at: sql`CURRENT_TIMESTAMP`, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskRuns.team_id, teamId), eq(taskRuns.id, runId)));
    await this.approvalNotifications.markApprovalNotifications({teamId, runId, status: "rejected"});
  }

  async approveTaskRun(
    teamId: string,
    runId: string,
    outputs: Record<string, NodeOutputValue>,
  ) {
    await this.database.update(taskRuns).set({status: "queued", response_outputs_json: json(outputs), reviewed_at: sql`CURRENT_TIMESTAMP`, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskRuns.team_id, teamId), eq(taskRuns.id, runId)));
    await this.approvalNotifications.markApprovalNotifications({teamId, runId, status: "accepted"});
  }

  private async insertRun(teamId: string, run: TaskRunDocument) {
    await this.database.insert(taskRuns).values({id: run.runId, team_id: teamId, task_id: run.taskId, task_title: run.taskTitle, status: "queued", context: run.context, input_json: json(run.input ?? {}), source: run.source ?? null, trigger_id: run.triggerId ?? null, trigger_type: run.triggerType ?? null});
  }

  private async updateStatus(teamId: string, runId: string, status: string) {
    await this.database.update(taskRuns).set({status, started_at: sql`CURRENT_TIMESTAMP`, updated_at: sql`CURRENT_TIMESTAMP`})
      .where(and(eq(taskRuns.team_id, teamId), eq(taskRuns.id, runId)));
  }

  private async loadRunRow(teamId: string, runId: string): Promise<TaskRunRow> {
    const row = (await this.database.select({id: taskRuns.id, task_id: taskRuns.task_id, task_title: taskRuns.task_title, context: taskRuns.context, input_json: taskRuns.input_json, resume_state_json: taskRuns.resume_state_json, response_outputs_json: taskRuns.response_outputs_json, status: taskRuns.status}).from(taskRuns).where(and(eq(taskRuns.team_id, teamId), eq(taskRuns.id, runId))).get()) ?? null;
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
