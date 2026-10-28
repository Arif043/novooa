import {type Activities, type TaskRuns} from "../../../../db/schema.js";

export type TaskRunRow = Pick<TaskRuns, "created_at" | "error_json" | "final_output" | "id" | "interaction_json" |
  "review_output" | "status" | "task_id" | "task_title" | "updated_at" | "waiting_node_id" | "started_at" | "completed_at" |
  "trigger_type" | "started_by_uid"> & {started_by_name: string | null};
export type ActivityRow = Pick<Activities, "created_at" | "id" | "input" | "message" | "node_id" | "output" |
  "outputs_json" | "console_json" | "conversation_json" | "effects_json" | "parent_node_id" | "iteration" | "selected_branch_id" | "failure_code" | "failure_details_json" | "primitive" | "run_id" | "status" | "target" | "title"> & {
  task_id: string; trigger_type: string | null;
  started_by_uid: string | null; started_by_name: string | null; reviewed_by_uid: string | null; reviewed_by_name: string | null;
};

/** Eine Person, die einen Lauf gestartet oder beantwortet hat; gelöschte Konten fallen weg. */
export type RunPersonDto = {uid: string; displayName: string} | null;

export type TaskRunDto = {
  runId: string; taskId: string; taskTitle: string; status: string; waitingNodeId: string | null;
  finalOutput: string; reviewOutput: string | null; interaction: unknown; error: unknown;
  createdAt: string; updatedAt: string; startedAt: string | null; completedAt: string | null;
  triggerType: string | null; startedBy: RunPersonDto;
};

export type ActivityDto = {
  id: string; runId: string; taskId: string; taskTitle: string; target: string; status: string; occurredAt: string;
  nodeId: string | null; primitive: string | null; input: string; output: string;
  outputs: Record<string, unknown>; message: string; failureCode: string | null;
  failureDetails: Record<string, string> | null; console: {stdout: string; stderr: string};
  /** Gespräch der Mitarbeiter einer Teamarbeit, wie gespeichert. */
  conversation: unknown[];
  /** Folgen des Bausteins (`RunEffect`), wie gespeichert. */
  effects: unknown[];
  parentNodeId: string | null; iteration: number | null; selectedBranchId: string | null;
  origin: {startedBy: RunPersonDto; reviewedBy: RunPersonDto; triggerType: string | null};
};

export function runFromRow(row: TaskRunRow): TaskRunDto {
  return {
    runId: row.id, taskId: row.task_id, taskTitle: row.task_title, status: row.status,
    waitingNodeId: row.waiting_node_id, finalOutput: row.final_output,
    reviewOutput: row.review_output, interaction: jsonValue(row.interaction_json),
    error: jsonValue(row.error_json), createdAt: isoTimestamp(row.created_at), updatedAt: isoTimestamp(row.updated_at),
    startedAt: optionalTimestamp(row.started_at), completedAt: optionalTimestamp(row.completed_at),
    triggerType: row.trigger_type, startedBy: personFrom(row.started_by_uid, row.started_by_name),
  };
}

export function activityFromRow(row: ActivityRow): ActivityDto {
  return {
    id: row.id, runId: row.run_id, taskId: row.task_id, taskTitle: row.title,
    target: row.target, status: row.status, occurredAt: isoTimestamp(row.created_at),
    nodeId: row.node_id, primitive: row.primitive, input: row.input, output: row.output,
    outputs: jsonRecord(row.outputs_json), message: row.message, failureCode: row.failure_code,
    failureDetails: failureDetailsFrom(row.failure_details_json), console: consoleFrom(row.console_json),
    conversation: jsonArray(row.conversation_json),
    effects: jsonArray(row.effects_json),
    parentNodeId: row.parent_node_id, iteration: row.iteration, selectedBranchId: row.selected_branch_id,
    origin: {
      startedBy: personFrom(row.started_by_uid, row.started_by_name),
      reviewedBy: personFrom(row.reviewed_by_uid, row.reviewed_by_name),
      triggerType: row.trigger_type,
    },
  };
}

function personFrom(uid: string | null, displayName: string | null): RunPersonDto {
  return uid === null || displayName === null ? null : {uid, displayName};
}

function failureDetailsFrom(value: string | null): Record<string, string> | null {
  if (value === null) return null;
  const parsed = jsonRecord(value);
  return Object.fromEntries(Object.entries(parsed).filter((entry): entry is [string, string] => typeof entry[1] === "string"));
}

function consoleFrom(value: string): {stdout: string; stderr: string} {
  const parsed = jsonRecord(value);
  return {
    stdout: typeof parsed.stdout === "string" ? parsed.stdout : "",
    stderr: typeof parsed.stderr === "string" ? parsed.stderr : "",
  };
}

function optionalTimestamp(value: string | null): string | null {
  return value === null ? null : isoTimestamp(value);
}

function isoTimestamp(value: string): string {
  return value.includes("T") ? value : `${value.replace(" ", "T")}Z`;
}

function jsonValue(value: string | null): unknown {
  if (value === null) return null;
  try {
    return JSON.parse(value) as unknown;
  } catch {
    return null;
  }
}

function jsonArray(value: string): unknown[] {
  const parsed = jsonValue(value);
  return Array.isArray(parsed) ? parsed : [];
}

function jsonRecord(value: string): Record<string, unknown> {
  const parsed = jsonValue(value);
  return parsed !== null && typeof parsed === "object" && !Array.isArray(parsed) ? parsed as Record<string, unknown> : {};
}
