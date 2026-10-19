import {Timestamp} from "firebase-admin/firestore";
import {
  type NodeExecutionResult,
  type NodeOutputValue,
} from "../../domain/entities/task.js";
import {
  type ActivityStore,
  type TaskActivityInput,
} from "../../domain/repositories/activity-store.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {type FailedNode} from "../../domain/entities/node-execution-failure.js";
import {type TaskRunDocument} from "../../domain/repositories/task-run-store.js";

export class FirestoreActivityStore implements ActivityStore {
  async writeNodeActivities(
    teamId: string,
    run: TaskRunDocument,
    results: NodeExecutionResult[],
  ) {
    for (const result of results) {
      await this.writeNodeActivity(teamId, run, result);
    }
  }

  async writeFailedNodeActivity(teamId: string, run: TaskRunDocument, failedNode: FailedNode) {
    const reference = activitiesReference(teamId).doc();
    await reference.set({
      ...baseActivity(reference.id, run, "node", "failed"),
      nodeId: failedNode.nodeId,
      primitive: failedNode.primitive,
      outputs: {},
      message: failedNode.message,
      ...(failedNode.failureCode ? {failureCode: failedNode.failureCode} : {}),
      ...(failedNode.failureDetails ? {failureDetails: failedNode.failureDetails} : {}),
      ...(failedNode.conversation?.length ? {conversation: failedNode.conversation} : {}),
    });
  }

  async writeTaskActivity(teamId: string, input: TaskActivityInput) {
    const reference = activitiesReference(teamId).doc();
    await reference.set({
      ...baseActivity(reference.id, input.run, "task", input.status),
      ...(input.input ? {input: input.input} : {}),
      ...(input.output ? {output: input.output.finalOutput} : {}),
      ...(input.message ? {message: input.message} : {}),
    });
  }

  private async writeNodeActivity(
    teamId: string,
    run: TaskRunDocument,
    result: NodeExecutionResult,
  ) {
    const reference = activitiesReference(teamId).doc();
    await reference.set({
      ...baseActivity(reference.id, run, "node", nodeStatus(result.status)),
      nodeId: result.nodeId,
      primitive: result.primitive,
      outputs: serializable(activityOutputsFor(result.outputs)),
      ...(result.message ? {message: result.message} : {}),
      ...(result.conversation?.length ? {conversation: result.conversation} : {}),
    });
  }
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

export function activityOutputsFor(
  outputs: Record<string, NodeOutputValue>,
): Record<string, NodeOutputValue> {
  return Object.fromEntries(Object.entries(outputs).map(([name, output]) => [
    name,
    activityOutputFor(output),
  ]));
}

function activityOutputFor(output: NodeOutputValue): NodeOutputValue {
  const metadata = dataUrlMetadataFor(output.value);
  if (metadata === null) return output;
  return {type: "json", value: metadata};
}

function dataUrlMetadataFor(value: unknown): DataUrlMetadata | null {
  if (typeof value !== "string") return null;
  const match = base64DataUrlPattern.exec(value);
  if (!match) return null;
  return {
    contentType: match[1].toLowerCase(),
    sizeBytes: base64ByteLength(match[2]),
  };
}

type DataUrlMetadata = {
  contentType: string;
  sizeBytes: number;
};

function base64ByteLength(value: string): number {
  const padding = value.endsWith("==") ? 2 : value.endsWith("=") ? 1 : 0;
  return (value.length / 4) * 3 - padding;
}

const base64DataUrlPattern = /^data:([^;,]+);base64,([A-Za-z0-9+/]+={0,2})$/i;

function serializable(value: unknown): unknown {
  return JSON.parse(JSON.stringify(value));
}

function activitiesReference(teamId: string) {
  return getDatabase().collection("teams").doc(teamId).collection("activities");
}
