import {type GenkitBeta} from "genkit/beta";
import {type NodeExecutionFailure} from "../../../domain/entities/node-execution-failure.js";
import {type TaskRunDocument} from "../../../domain/repositories/task-run-store.js";
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
    const runOrFailure = await executeQueuedTaskRun(ai, {teamId, run, stores}, logger);
    if (!runOrFailure.ok) await failRun(logger, stores, teamId, run, runOrFailure.failure);
  } catch (error) {
    await failRunUnexpectedly(logger, stores, teamId, run, error);
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
  const run = resumableRun.run;
  try {
    const runOrFailure = await continueApprovedTaskRun(ai, {...resumableRun, teamId, stores}, logger);
    if (!runOrFailure.ok) await failRun(logger, stores, teamId, run, runOrFailure.failure);
  } catch (error) {
    await failRunUnexpectedly(logger, stores, teamId, run, error);
  }
}

/**
 * Ein Baustein ist gescheitert: Der Lauf wird als fehlgeschlagen festgehalten, samt der Bausteine
 * davor. Geworfen wird nur noch, weil die Warteschlange das Scheitern des Auftrags erfahren muss.
 */
async function failRun(
  logger: ApplicationLogger,
  stores: TaskRunWorkerStores,
  teamId: string,
  run: TaskRunDocument,
  failure: NodeExecutionFailure,
): Promise<never> {
  logRunError(logger, "task_run_task.failed", teamId, run.runId, run.taskId, failure.cause);
  await stores.taskRunStore.markRunFailed(teamId, run, failure.cause, failure);
  throw failure.cause;
}

/** Ein Fehler außerhalb der Bausteine (Laden, Speichern, ungültiger Plan): Der Lauf scheitert ohne Baustein-Einzelheiten. */
async function failRunUnexpectedly(
  logger: ApplicationLogger,
  stores: TaskRunWorkerStores,
  teamId: string,
  run: TaskRunDocument,
  error: unknown,
): Promise<never> {
  logRunError(logger, "task_run_task.failed", teamId, run.runId, run.taskId, error);
  await stores.taskRunStore.markRunFailed(teamId, run, error);
  throw error;
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
