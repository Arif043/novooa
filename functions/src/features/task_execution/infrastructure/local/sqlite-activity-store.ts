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
import {type TaskRunDocument} from "../../domain/repositories/task-run-store.js";

export class SQLiteActivityStore implements ActivityStore {
  constructor(private readonly database: RuntimeExecutor) {}

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
    await this.database.insert(activities).values({id: randomUUID(), team_id: teamId, run_id: input.run.runId, task_id: input.run.taskId, node_id: null, target: "task", primitive: null, title: input.run.taskTitle, status: input.status, input: input.input ?? "", output: input.output?.finalOutput ?? "", outputs_json: "{}", message: input.message ?? "", duration_ms: null});
  }

  private async writeNodeActivity(
    teamId: string,
    run: TaskRunDocument,
    result: NodeExecutionResult,
  ) {
    await this.database.insert(activities).values({id: randomUUID(), team_id: teamId, run_id: run.runId, task_id: run.taskId, node_id: result.nodeId, target: "node", primitive: result.primitive, title: result.nodeId, status: nodeStatus(result.status), input: "", output: "", outputs_json: JSON.stringify(result.outputs), message: result.message ?? "", duration_ms: null});
  }
}

function nodeStatus(status: NodeExecutionResult["status"]): string {
  if (status === "executed") return "succeeded";
  if (status === "waitingForApproval") return "waiting";
  return "skipped";
}
