import {FieldValue} from "firebase-admin/firestore";
import {type CompletedTaskGraphOutput} from "../task-definition.js";

export function runStatus(status: string) {
  return {status, updatedAt: FieldValue.serverTimestamp()};
}

export function successDocument(
  output: CompletedTaskGraphOutput,
) {
  return {
    ...runStatus("succeeded"),
    finalOutput: output.finalOutput,
    nodeResults: serializable(output.nodeResults),
    waitingNodeId: FieldValue.delete(),
    resumeState: FieldValue.delete(),
    reviewInstruction: FieldValue.delete(),
    reviewOutput: FieldValue.delete(),
    approvedOutput: FieldValue.delete(),
    pausedAt: FieldValue.delete(),
  };
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
    pausedAt: FieldValue.delete(),
  };
}

export function approvedDocument(output: string) {
  return {
    status: "queued",
    approvedOutput: output,
    updatedAt: FieldValue.serverTimestamp(),
    waitingNodeId: FieldValue.delete(),
    reviewInstruction: FieldValue.delete(),
    reviewOutput: FieldValue.delete(),
    pausedAt: FieldValue.delete(),
  };
}

export function serializable(value: unknown): unknown {
  return JSON.parse(JSON.stringify(value));
}
