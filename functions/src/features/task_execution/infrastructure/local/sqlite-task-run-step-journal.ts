import {and, eq, inArray} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {taskRunSteps} from "../../../../db/schema.js";
import {type NodeExecutionResult} from "../../domain/entities/task.js";
import {type TaskRunStepKey} from "../../domain/entities/task-run-step-key.js";
import {type TaskRunStepJournal} from "../../domain/repositories/task-run-step-journal.js";
import {nodeExecutionResultSchema} from "../genkit/runner/task-definition.js";
import {requireTeamRun, teamRunId} from "./sqlite-team-run.js";

export class SQLiteTaskRunStepJournal implements TaskRunStepJournal {
  constructor(private readonly database: RuntimeExecutor) {}

  async find(key: TaskRunStepKey): Promise<NodeExecutionResult | null> {
    const row = await this.database.select({result_json: taskRunSteps.result_json}).from(taskRunSteps)
      .where(stepMatching(this.database, key)).get();
    if (row === undefined) return null;
    return nodeExecutionResultSchema.parse(JSON.parse(row.result_json));
  }

  async record(key: TaskRunStepKey, result: NodeExecutionResult): Promise<void> {
    await this.database.transaction(async (tx) => {
      await requireTeamRun(tx, key.teamId, key.runId);
      await tx.insert(taskRunSteps).values({
        run_id: key.runId, step_path: key.stepPath, result_json: JSON.stringify(result),
      }).onConflictDoNothing();
    });
  }

  async clear(teamId: string, runId: string): Promise<void> {
    await this.database.delete(taskRunSteps)
      .where(inArray(taskRunSteps.run_id, teamRunId(this.database, teamId, runId)));
  }
}

function stepMatching(database: RuntimeExecutor, key: TaskRunStepKey) {
  return and(
    inArray(taskRunSteps.run_id, teamRunId(database, key.teamId, key.runId)),
    eq(taskRunSteps.step_path, key.stepPath),
  );
}
