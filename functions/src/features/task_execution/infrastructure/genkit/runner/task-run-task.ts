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
  const runOrFailure = await rethrowingUnexpected(
    () => executeQueuedTaskRun(ai, {teamId, run, stores}, logger),
    (error) => failRunAfterUnexpectedError(logger, stores, teamId, run, error),
  );
  await runOrFailure.match(
    async () => undefined,
    (failure) => failRunAfterNodeFailure(logger, stores, teamId, run, failure),
  );
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
  const runOrFailure = await rethrowingUnexpected(
    () => continueApprovedTaskRun(ai, {...resumableRun, teamId, stores}, logger),
    (error) => failRunAfterUnexpectedError(logger, stores, teamId, run, error),
  );
  await runOrFailure.match(
    async () => undefined,
    (failure) => failRunAfterNodeFailure(logger, stores, teamId, run, failure),
  );
}

/**
 * Fehler außerhalb der Bausteine (Laden, Speichern, ungültiger Plan) bleiben Exceptions: Der Lauf
 * wird festgehalten, dann scheitert der Auftrag, damit die Warteschlange ihn wiederholen darf.
 */
async function rethrowingUnexpected<T>(
  work: () => Promise<T>,
  onUnexpected: (error: unknown) => Promise<void>,
): Promise<T> {
  try {
    return await work();
  } catch (error) {
    await onUnexpected(error);
    throw error;
  }
}

/**
 * Ein Baustein ist gescheitert: Der Lauf wird als fehlgeschlagen festgehalten, samt der Bausteine
 * davor. Es wird nicht geworfen, denn der Auftrag selbst ist erledigt; eine Wiederholung würde die
 * Bausteine erneut ausführen und denselben Fehler nur doppelt in die Aktivitäten schreiben.
 */
async function failRunAfterNodeFailure(
  logger: ApplicationLogger,
  stores: TaskRunWorkerStores,
  teamId: string,
  run: TaskRunDocument,
  failure: NodeExecutionFailure,
) {
  logRunError(logger, "task_run_task.failed", teamId, run.runId, run.taskId, failure.cause);
  await stores.taskRunStore.markRunFailed(teamId, run, failure.cause, failure);
}

/** Ein Fehler außerhalb der Bausteine (Laden, Speichern, ungültiger Plan): Der Lauf scheitert ohne Baustein-Einzelheiten, der Auftrag darf wiederholt werden. */
async function failRunAfterUnexpectedError(
  logger: ApplicationLogger,
  stores: TaskRunWorkerStores,
  teamId: string,
  run: TaskRunDocument,
  error: unknown,
) {
  logRunError(logger, "task_run_task.failed", teamId, run.runId, run.taskId, error);
  await stores.taskRunStore.markRunFailed(teamId, run, error);
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
