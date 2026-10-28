import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {writeActivity} from "./sqlite-activity-write.js";
import {type NodeExecutionResult} from "../../domain/entities/task.js";
import {type ActivityStore, type TaskActivityInput} from "../../domain/repositories/activity-store.js";
import {type FailedNode} from "../../domain/entities/node-execution-failure.js";
import {type TaskRunDocument} from "../../domain/repositories/task-run-store.js";
import {type ActivityRowDraft, failedRows, resultRows} from "./nested-activity-rows.js";

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

  /** Je Baustein eine Zeile, dazu die Zeilen seiner Zweige und Schleifenrunden. */
  async writeNodeActivities(teamId: string, run: TaskRunDocument, results: NodeExecutionResult[]) {
    for (const result of results) await this.writeRows(teamId, run, resultRows(result, {runId: run.runId}));
  }

  async writeTaskActivity(teamId: string, input: TaskActivityInput) {
    await writeActivity(this.database, teamId, input.run.taskId, {id: randomUUID(), run_id: input.run.runId, node_id: null, target: "task", primitive: null, title: input.run.taskTitle, status: input.status, input: input.input ?? "", output: input.output?.finalOutput ?? "", outputs_json: "{}", message: input.message ?? "", duration_ms: null, created_at: this.nextTimestamp()});
  }

  async writeFailedNodeActivity(teamId: string, run: TaskRunDocument, failedNode: FailedNode) {
    await this.writeRows(teamId, run, failedRows(failedNode, {runId: run.runId}));
  }

  private async writeRows(teamId: string, run: TaskRunDocument, rows: ActivityRowDraft[]) {
    for (const row of rows) {
      await writeActivity(this.database, teamId, run.taskId, {...row, id: randomUUID(), created_at: this.nextTimestamp()});
    }
  }
}
