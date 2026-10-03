import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {activities} from "../../../../db/schema.js";
import {
  type NodeExecutionResult,
} from "../../domain/entities/task.js";
import {
  type ActivityStore,
  type TaskActivityInput,
} from "../../domain/repositories/activity-store.js";
import {type FailedNode} from "../../domain/services/run-failure-details.js";
import {type TaskRunDocument} from "../../domain/repositories/task-run-store.js";

export class SQLiteActivityStore implements ActivityStore {
  private lastTimestamp = 0;

  constructor(private readonly database: RuntimeExecutor) {}

  /**
   * Streng steigende Zeitstempel mit Millisekunden: Die Aktivitäten eines Laufs entstehen im selben
   * Moment, und ihre Reihenfolge ist die der Bausteine im Plan. Mit Sekundenauflösung wäre sie zufällig.
   */
  private nextTimestamp(): string {
    this.lastTimestamp = Math.max(Date.now(), this.lastTimestamp + 1);
    return new Date(this.lastTimestamp).toISOString().replace("T", " ").replace("Z", "");
  }

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
    await this.database.insert(activities).values({id: randomUUID(), team_id: teamId, run_id: input.run.runId, task_id: input.run.taskId, node_id: null, target: "task", primitive: null, title: input.run.taskTitle, status: input.status, input: input.input ?? "", output: input.output?.finalOutput ?? "", outputs_json: "{}", message: input.message ?? "", duration_ms: null, created_at: this.nextTimestamp()});
  }

  async writeFailedNodeActivity(teamId: string, run: TaskRunDocument, failedNode: FailedNode) {
    await this.database.insert(activities).values({id: randomUUID(), team_id: teamId, run_id: run.runId, task_id: run.taskId, node_id: failedNode.nodeId, target: "node", primitive: failedNode.primitive, title: failedNode.nodeId, status: "failed", input: "", output: "", outputs_json: "{}", message: failedNode.message, console_json: JSON.stringify(failedNode.console ?? {}), duration_ms: null, created_at: this.nextTimestamp()});
  }

  private async writeNodeActivity(
    teamId: string,
    run: TaskRunDocument,
    result: NodeExecutionResult,
  ) {
    await this.database.insert(activities).values({id: randomUUID(), team_id: teamId, run_id: run.runId, task_id: run.taskId, node_id: result.nodeId, target: "node", primitive: result.primitive, title: result.nodeId, status: nodeStatus(result.status), input: "", output: "", outputs_json: JSON.stringify(result.outputs), message: result.message ?? "", console_json: JSON.stringify(result.console ?? {}), duration_ms: null, created_at: this.nextTimestamp()});
  }
}

function nodeStatus(status: NodeExecutionResult["status"]): string {
  if (status === "executed") return "succeeded";
  if (status === "waitingForApproval") return "waiting";
  return "skipped";
}
