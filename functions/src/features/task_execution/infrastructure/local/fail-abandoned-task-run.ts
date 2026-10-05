import {type TaskRunStore} from "../../domain/repositories/task-run-store.js";
import {type LeasedTaskRunJob} from "./sqlite-task-run-job-store.js";

const abandonedRunMessage =
  "Die Ausführung wurde wiederholt durch einen Absturz der Runtime unterbrochen und wird nicht erneut gestartet.";

/** Ohne diesen Schritt bliebe ein aufgegebener Run für immer auf „läuft“ stehen. */
export async function failAbandonedTaskRun(
  taskRunStore: TaskRunStore,
  job: LeasedTaskRunJob,
): Promise<void> {
  const run = await taskRunStore.loadTaskRun(job.teamId, job.runId);
  await taskRunStore.markRunFailed(job.teamId, run, new Error(abandonedRunMessage));
}
