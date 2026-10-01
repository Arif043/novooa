import {type Activities, type TaskRuns} from "../../../../db/schema.js";

export type TaskRunRow = Pick<TaskRuns, "created_at" | "error_json" | "final_output" | "id" | "interaction_json" |
  "review_output" | "status" | "task_id" | "task_title" | "updated_at" | "waiting_node_id">;
export type ActivityRow = Pick<Activities, "created_at" | "id" | "input" | "message" | "node_id" | "output" |
  "outputs_json" | "primitive" | "run_id" | "status" | "target" | "task_id" | "title">;

export type TaskRunDto = {
  runId: string; taskId: string; taskTitle: string; status: string; waitingNodeId: string | null;
  finalOutput: string; reviewOutput: string | null; interaction: unknown; error: unknown;
  createdAt: string; updatedAt: string;
};

export type ActivityDto = {
  id: string; runId: string; taskId: string; taskTitle: string; target: string; status: string; occurredAt: string;
  nodeId: string | null; primitive: string | null; input: string; output: string;
  outputs: Record<string, unknown>; message: string;
};

export function runFromRow(row: TaskRunRow): TaskRunDto {
  return {
    runId: row.id, taskId: row.task_id, taskTitle: row.task_title, status: row.status,
    waitingNodeId: row.waiting_node_id, finalOutput: row.final_output,
    reviewOutput: row.review_output, interaction: jsonValue(row.interaction_json),
    error: jsonValue(row.error_json), createdAt: isoTimestamp(row.created_at), updatedAt: isoTimestamp(row.updated_at),
  };
}

export function activityFromRow(row: ActivityRow): ActivityDto {
  return {
    id: row.id, runId: row.run_id, taskId: row.task_id, taskTitle: row.title,
    target: row.target, status: row.status, occurredAt: isoTimestamp(row.created_at),
    nodeId: row.node_id, primitive: row.primitive, input: row.input, output: row.output,
    outputs: jsonRecord(row.outputs_json), message: row.message,
  };
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

function jsonRecord(value: string): Record<string, unknown> {
  const parsed = jsonValue(value);
  return parsed !== null && typeof parsed === "object" && !Array.isArray(parsed) ? parsed as Record<string, unknown> : {};
}
