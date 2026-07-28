import {type GenkitBeta} from "genkit/beta";
import {z} from "zod";
import {errorDetails, logError, logInfo} from "./structured-logger.js";
import {
  continueApprovedTaskRun,
  executeQueuedTaskRun,
  type TaskRunWorkerStores,
} from "./task-run-worker.js";

export const taskRunDispatchPayloadSchema = z.object({
  teamId: z.string(),
  runId: z.string(),
  mode: z.enum(["start", "resume"]),
});

export type TaskRunDispatchPayload =
  z.infer<typeof taskRunDispatchPayloadSchema>;

export async function handleTaskRunDispatch(
  ai: GenkitBeta,
  payload: TaskRunDispatchPayload,
  stores: TaskRunWorkerStores,
) {
  logInfo("task_run_task.started", payload);
  if (payload.mode === "resume") {
    await resumeTaskRun(ai, payload.teamId, payload.runId, stores);
    return;
  }
  await startTaskRun(ai, payload.teamId, payload.runId, stores);
}

async function startTaskRun(
  ai: GenkitBeta,
  teamId: string,
  runId: string,
  stores: TaskRunWorkerStores,
) {
  const run = await stores.taskRunStore.loadTaskRun(teamId, runId);
  try {
    await executeQueuedTaskRun(ai, {teamId, run, stores});
  } catch (error) {
    logRunError("task_run_task.failed", teamId, run.runId, run.taskId, error);
    await stores.taskRunStore.markRunFailed(teamId, run, error);
    throw error;
  }
}

async function resumeTaskRun(
  ai: GenkitBeta,
  teamId: string,
  runId: string,
  stores: TaskRunWorkerStores,
) {
  const resumableRun = await stores.taskRunStore.loadResumableRun(teamId, runId);
  try {
    await continueApprovedTaskRun(ai, {...resumableRun, teamId, stores});
  } catch (error) {
    const run = resumableRun.run;
    logRunError("task_run_task.failed", teamId, run.runId, run.taskId, error);
    await stores.taskRunStore.markRunFailed(teamId, run, error);
    throw error;
  }
}

function logRunError(
  event: string,
  teamId: string,
  runId: string,
  taskId: string,
  error: unknown,
) {
  logError(event, {teamId, taskId, runId, error: errorDetails(error)});
}
