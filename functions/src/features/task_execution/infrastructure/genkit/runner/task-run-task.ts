import {runFailureDetailsOf} from "../../../domain/services/run-failure-details.js";
import {type GenkitBeta} from "genkit/beta";
import {z} from "zod";
import {
  errorDetails,
  type ApplicationLogger,
} from "../../../../../shared/logging/application-logger.js";
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
  logger: ApplicationLogger,
) {
  logger.info("task_run_task.started", payload);
  if (payload.mode === "resume") {
    await resumeTaskRun(ai, payload.teamId, payload.runId, stores, logger);
    return;
  }
  await startTaskRun(ai, payload.teamId, payload.runId, stores, logger);
}

async function startTaskRun(
  ai: GenkitBeta,
  teamId: string,
  runId: string,
  stores: TaskRunWorkerStores,
  logger: ApplicationLogger,
) {
  const run = await stores.taskRunStore.loadTaskRun(teamId, runId);
  try {
    await executeQueuedTaskRun(ai, {teamId, run, stores}, logger);
  } catch (error) {
    logRunError(logger, "task_run_task.failed", teamId, run.runId, run.taskId, error);
    await stores.taskRunStore.markRunFailed(teamId, run, error, runFailureDetailsOf(error));
    throw error;
  }
}

async function resumeTaskRun(
  ai: GenkitBeta,
  teamId: string,
  runId: string,
  stores: TaskRunWorkerStores,
  logger: ApplicationLogger,
) {
  const resumableRun = await stores.taskRunStore.loadResumableRun(teamId, runId);
  try {
    await continueApprovedTaskRun(ai, {...resumableRun, teamId, stores}, logger);
  } catch (error) {
    const run = resumableRun.run;
    logRunError(logger, "task_run_task.failed", teamId, run.runId, run.taskId, error);
    await stores.taskRunStore.markRunFailed(teamId, run, error, runFailureDetailsOf(error));
    throw error;
  }
}

function logRunError(
  logger: ApplicationLogger,
  event: string,
  teamId: string,
  runId: string,
  taskId: string,
  error: unknown,
) {
  logger.error(event, {teamId, taskId, runId, error: errorDetails(error)});
}
