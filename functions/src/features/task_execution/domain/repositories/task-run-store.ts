import {randomUUID} from "crypto";
import {type NodeExecutionFailure} from "../entities/node-execution-failure.js";
import {
  type CompletedTaskGraphOutput,
  type NodeOutputValue,
  type TaskDefinition,
  type TaskResumeState,
  type WaitingTaskGraphOutput,
} from "../entities/task.js";

export type TaskRunDocument = {
  runId: string;
  taskId: string;
  taskTitle: string;
  context: string;
  input?: Record<string, unknown>;
  source?: string;
  triggerId?: string;
  triggerType?: string;
  /** Wer den Lauf von Hand gestartet hat; automatische Läufe tragen nur ihren Auslöser. */
  startedByUid?: string;
  /** Die Aufgabe beim Start. Start und Fortsetzen laufen damit, auch wenn die Aufgabe inzwischen
   * geändert wurde; fehlt bei älteren Läufen. */
  graphSnapshot?: TaskDefinition;
};

export type ReviewableTaskRun = {
  run: TaskRunDocument;
  resumeState: TaskResumeState;
};

export type ResumableTaskRun = ReviewableTaskRun & {
  responseOutputs: Record<string, NodeOutputValue>;
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
  /** Nur bei manuellem Start: die angemeldete Person. */
  startedByUid?: string;
};

export interface TaskRunStore {
  enqueueTaskRun(input: EnqueueTaskRunInput): Promise<TaskRunDocument>;
  loadTaskRun(teamId: string, runId: string): Promise<TaskRunDocument>;
  loadResumableRun(teamId: string, runId: string): Promise<ResumableTaskRun>;
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
  /**
   * Der Lauf schlägt fehl; die Bausteine davor und der fehlgeschlagene Baustein ([failure]) werden
   * trotzdem als Baustein-Aktivitäten an ihrer Position festgehalten.
   */
  markRunFailed(
    teamId: string,
    run: TaskRunDocument,
    error: unknown,
    failure?: NodeExecutionFailure,
  ): Promise<void>;
  loadReviewableRun(teamId: string, runId: string): Promise<ReviewableTaskRun>;
  /** [reviewedByUid]: wer die Freigabe oder das Formular beantwortet hat. */
  rejectTaskRun(teamId: string, runId: string, reviewedByUid: string): Promise<void>;
  approveTaskRun(
    teamId: string,
    runId: string,
    outputs: Record<string, NodeOutputValue>,
    reviewedByUid: string,
  ): Promise<void>;
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
    ...(input.startedByUid === undefined ? {} : {startedByUid: input.startedByUid}),
    graphSnapshot: input.task,
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

function inputFromDocument(value: unknown): Record<string, unknown> {
  return isRecord(value) ? value : {};
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
