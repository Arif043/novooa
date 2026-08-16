import {FieldValue} from "firebase-admin/firestore";
import {
  taskResumeStateSchema,
} from "../genkit/runner/task-definition.js";
import {
  type TaskResumeState,
  type NodeOutputValue,
} from "../../domain/entities/task.js";

export function runStatus(status: string) {
  return {status, updatedAt: FieldValue.serverTimestamp()};
}

export function rejectedDocument() {
  return {
    status: "rejected",
    updatedAt: FieldValue.serverTimestamp(),
    rejectedAt: FieldValue.serverTimestamp(),
    waitingNodeId: FieldValue.delete(),
    finalOutput: FieldValue.delete(),
    nodeResults: FieldValue.delete(),
    resumeState: FieldValue.delete(),
    reviewInstruction: FieldValue.delete(),
    reviewOutput: FieldValue.delete(),
    dialogInput: FieldValue.delete(),
    pausedAt: FieldValue.delete(),
  };
}

export function approvedDocument(outputs: Record<string, NodeOutputValue>) {
  return {
    status: "queued",
    responseOutputs: serializable(outputs),
    approvedOutput: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
    waitingNodeId: FieldValue.delete(),
    reviewInstruction: FieldValue.delete(),
    reviewOutput: FieldValue.delete(),
    dialogInput: FieldValue.delete(),
    pausedAt: FieldValue.delete(),
  };
}

export function serializable(value: unknown): unknown {
  return JSON.parse(JSON.stringify(value));
}

export function resumeStateFromDocument(
  data: Record<string, unknown>,
): TaskResumeState {
  return taskResumeStateSchema.parse(data.resumeState);
}
