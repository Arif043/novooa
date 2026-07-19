import {randomUUID} from "crypto";
import {
  type CompletedTaskGraphOutput,
  type TaskDefinition,
  taskResumeStateSchema,
  type TaskResumeState,
  type WaitingTaskGraphOutput,
} from "../task-definition.js";

export type TaskRunDocument = {
  runId: string;
  taskId: string;
  taskTitle: string;
  context: string;
  input?: Record<string, unknown>;
  source?: string;
  triggerId?: string;
  triggerType?: string;
};

export type ReviewableTaskRun = {
  run: TaskRunDocument;
  resumeState: TaskResumeState;
};

export type EnqueueTaskRunInput = {
  teamId: string;
  task: TaskDefinition;
  context: string;
  input?: Record<string, unknown>;
  trigger?: {
    id: string;
    type: string;
  };
};

export interface TaskRunStore {
  enqueueTaskRun(input: EnqueueTaskRunInput): Promise<TaskRunDocument>;
  markRunStarted(teamId: string, runId: string): Promise<void>;
  markRunSucceeded(
    teamId: string,
    run: TaskRunDocument,
    output: CompletedTaskGraphOutput,
  ): Promise<void>;
  markRunWaitingForApproval(
    teamId: string,
    run: TaskRunDocument,
    output: WaitingTaskGraphOutput,
  ): Promise<void>;
  markRunFailed(
    teamId: string,
    run: TaskRunDocument,
    error: unknown,
  ): Promise<void>;
  loadReviewableRun(teamId: string, runId: string): Promise<ReviewableTaskRun>;
  rejectTaskRun(teamId: string, runId: string): Promise<void>;
  approveTaskRun(teamId: string, runId: string, output: string): Promise<void>;
}

export function newTaskRunDocument(
  input: Omit<EnqueueTaskRunInput, "teamId">,
): TaskRunDocument {
  return {
    runId: randomUUID(),
    taskId: input.task.id,
    taskTitle: input.task.title,
    context: input.context,
    input: input.input,
    ...(input.trigger ? {
      source: "trigger",
      triggerId: input.trigger.id,
      triggerType: input.trigger.type,
    } : {}),
  };
}

export function runFromDocument(data: Record<string, unknown>) {
  return {
    runId: String(data.runId ?? ""),
    taskId: String(data.taskId ?? ""),
    taskTitle: String(data.taskTitle ?? "Unbenannte Aufgabe"),
    context: String(data.context ?? ""),
    input: inputFromDocument(data.input),
  };
}

export function resumeStateFromDocument(data: Record<string, unknown>) {
  return taskResumeStateSchema.parse(data.resumeState);
}

function inputFromDocument(value: unknown): Record<string, unknown> {
  return isRecord(value) ? value as Record<string, unknown> : {};
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
