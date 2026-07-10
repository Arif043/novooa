import {randomUUID} from "crypto";
import {getApps, initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  type DocumentData,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import {
  type CompletedTaskGraphOutput,
  type NodeExecutionResult,
  type TaskDefinition,
  type WaitingTaskGraphOutput,
} from "./task-definition.js";
import {errorDetails} from "./structured-logger.js";

export type TaskRunDocument = {
  runId: string;
  taskId: string;
  taskTitle: string;
  context: string;
};

export async function enqueueTaskRun(input: {
  teamId: string;
  task: TaskDefinition;
  context: string;
}): Promise<TaskRunDocument> {
  const run = runDocument(input);
  await runReference(input.teamId, run.runId).set({
    ...run,
    status: "queued",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await writeTaskActivity(input.teamId, {
    run,
    status: "started",
    input: input.context,
  });
  return run;
}

export async function markRunStarted(teamId: string, runId: string) {
  await runReference(teamId, runId).set(runStatus("running"), {merge: true});
}

export async function markRunSucceeded(
  teamId: string,
  run: TaskRunDocument,
  output: CompletedTaskGraphOutput,
) {
  await writeNodeActivities(teamId, run, output.nodeResults);
  await writeTaskActivity(teamId, {run, status: "succeeded", output});
  await runReference(teamId, run.runId).set({
    ...runStatus("succeeded"),
    finalOutput: output.finalOutput,
    nodeResults: serializable(output.nodeResults),
    waitingNodeId: FieldValue.delete(),
    resumeState: FieldValue.delete(),
    reviewInstruction: FieldValue.delete(),
    reviewOutput: FieldValue.delete(),
    approvedOutput: FieldValue.delete(),
    pausedAt: FieldValue.delete(),
  }, {
    merge: true,
  });
}

export async function markRunWaitingForApproval(
  teamId: string,
  run: TaskRunDocument,
  output: WaitingTaskGraphOutput,
) {
  const review = reviewFieldsFrom(output);
  await writeNodeActivities(teamId, run, output.nodeResults);
  await runReference(teamId, run.runId).set({
    ...runStatus("waitingForApproval"),
    waitingNodeId: output.resumeState.waitingNodeId,
    finalOutput: output.finalOutput,
    reviewInstruction: review.instruction,
    reviewOutput: review.output,
    resumeState: serializable(output.resumeState),
    pausedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
}

export async function markRunFailed(
  teamId: string,
  run: TaskRunDocument,
  error: unknown,
) {
  const details = errorDetails(error);
  await writeTaskActivity(teamId, {
    run,
    status: "failed",
    message: errorMessage(details),
  });
  await runReference(teamId, run.runId).set({
    ...runStatus("failed"),
    error: details,
  }, {merge: true});
}

export function runFromDocument(data: DocumentData) {
  return {
    runId: String(data.runId ?? ""),
    taskId: String(data.taskId ?? ""),
    taskTitle: String(data.taskTitle ?? "Unbenannte Aufgabe"),
    context: String(data.context ?? ""),
  };
}

function runDocument(input: {
  task: TaskDefinition;
  context: string;
}): TaskRunDocument {
  return {
    runId: randomUUID(),
    taskId: input.task.id,
    taskTitle: input.task.title,
    context: input.context,
  };
}

function reviewFieldsFrom(output: WaitingTaskGraphOutput) {
  const result = output.resumeState.nodeResults.find(
    (item) => item.nodeId === output.resumeState.waitingNodeId,
  );
  return {
    instruction: result?.message ?? "Prüfe das Ergebnis und gib es frei.",
    output: result?.output ?? output.finalOutput,
  };
}

async function writeNodeActivities(
  teamId: string,
  run: TaskRunDocument,
  results: NodeExecutionResult[],
) {
  for (const result of results) {
    await writeNodeActivity(teamId, run, result);
  }
}

async function writeNodeActivity(
  teamId: string,
  run: TaskRunDocument,
  result: NodeExecutionResult,
) {
  const reference = activitiesReference(teamId).doc();
  await reference.set({
    ...baseActivity(reference.id, run, "node", nodeStatus(result.status)),
    nodeId: result.nodeId,
    primitive: result.primitive,
    output: result.output,
    ...(result.message ? {message: result.message} : {}),
  });
}

async function writeTaskActivity(
  teamId: string,
  input: {
    run: TaskRunDocument;
    status: "started" | "succeeded" | "failed";
    input?: string;
    output?: CompletedTaskGraphOutput;
    message?: string;
  },
) {
  const reference = activitiesReference(teamId).doc();
  await reference.set({
    ...baseActivity(reference.id, input.run, "task", input.status),
    ...(input.input ? {input: input.input} : {}),
    ...(input.output ? {output: input.output.finalOutput} : {}),
    ...(input.message ? {message: input.message} : {}),
  });
}

function baseActivity(
  id: string,
  run: TaskRunDocument,
  target: "task" | "node",
  status: string,
) {
  return {
    id,
    runId: run.runId,
    taskId: run.taskId,
    taskTitle: run.taskTitle,
    target,
    status,
    occurredAt: Timestamp.now(),
  };
}

function nodeStatus(status: NodeExecutionResult["status"]): string {
  if (status === "executed") return "succeeded";
  if (status === "waitingForApproval") return "waiting";
  return "skipped";
}

function errorMessage(details: unknown): string {
  if (isObject(details) && typeof details.message === "string") {
    return details.message;
  }
  return String(details);
}

function runStatus(status: string) {
  return {status, updatedAt: FieldValue.serverTimestamp()};
}

function serializable(value: unknown): unknown {
  return JSON.parse(JSON.stringify(value));
}

function activitiesReference(teamId: string) {
  return getDatabase().collection("teams").doc(teamId).collection("activities");
}

function runReference(teamId: string, runId: string) {
  return getDatabase().collection("teams").doc(teamId).collection("taskRuns")
    .doc(runId);
}

function getDatabase() {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}

function isObject(value: unknown): value is {message?: unknown} {
  return typeof value === "object" && value !== null;
}
