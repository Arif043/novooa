import {Timestamp} from "firebase-admin/firestore";
import {
  type NodeExecutionResult,
} from "../../domain/entities/task.js";
import {
  type ActivityStore,
  type TaskActivityInput,
} from "../../domain/repositories/activity-store.js";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
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
      outputs: serializable(result.outputs),
      ...(result.message ? {message: result.message} : {}),
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

function serializable(value: unknown): unknown {
  return JSON.parse(JSON.stringify(value));
}

function activitiesReference(teamId: string) {
  return getDatabase().collection("teams").doc(teamId).collection("activities");
}
