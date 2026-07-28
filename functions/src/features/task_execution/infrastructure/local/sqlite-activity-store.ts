import {randomUUID} from "node:crypto";
import {
  type NodeExecutionResult,
} from "../../domain/entities/task.js";
import {
  type ActivityStore,
  type TaskActivityInput,
} from "../../domain/repositories/activity-store.js";
import {type TaskRunDocument} from "../../domain/repositories/task-run-store.js";
import {type LocalSqlDatabase} from "../../../../shared/local/local-sql-database.js";

export class SQLiteActivityStore implements ActivityStore {
  constructor(private readonly database: LocalSqlDatabase) {}

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
    await this.database.run(insertSql(), [
      randomUUID(),
      teamId,
      input.run.runId,
      input.run.taskId,
      null,
      "task",
      null,
      input.run.taskTitle,
      input.status,
      input.input ?? "",
      input.output?.finalOutput ?? "",
      "{}",
      input.message ?? "",
      null,
    ]);
  }

  private async writeNodeActivity(
    teamId: string,
    run: TaskRunDocument,
    result: NodeExecutionResult,
  ) {
    await this.database.run(insertSql(), [
      randomUUID(),
      teamId,
      run.runId,
      run.taskId,
      result.nodeId,
      "node",
      result.primitive,
      result.nodeId,
      nodeStatus(result.status),
      "",
      "",
      JSON.stringify(result.outputs),
      result.message ?? "",
      null,
    ]);
  }
}

function insertSql() {
  return `INSERT INTO activities(id, team_id, run_id, task_id, node_id, target,
    primitive, title, status, input, output, outputs_json, message, duration_ms)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
}

function nodeStatus(status: NodeExecutionResult["status"]): string {
  if (status === "executed") return "succeeded";
  if (status === "waitingForApproval") return "waiting";
  return "skipped";
}
