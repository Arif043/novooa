import {type TaskGraphRuntime} from "./task-graph-runtime.js";
import {type GenkitBeta} from "genkit/beta";
import {
  executeTaskGraph,
  resumeTaskGraph,
} from "./task-graph-runner.js";
import {
  type TaskGraphOutput,
  type TaskResumeState,
  type NodeOutputValue,
} from "./task-definition.js";
import {type NodeExecutionFailure} from "../../../domain/entities/node-execution-failure.js";
import {type TaskStore} from "../../../domain/repositories/task-store.js";
import {
  type TaskRunDocument,
  type TaskRunStore,
} from "../../../domain/repositories/task-run-store.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";
import {type Result} from "neverthrow";

/** Alles, was ein Worker braucht: die Laufzeit des Graphen (ohne Logger, den bringt der Aufrufer) plus die Stores für Aufgaben und Läufe. */
export type TaskRunWorkerStores = Omit<TaskGraphRuntime, "logger"> & {
  taskStore: TaskStore;
  taskRunStore: TaskRunStore;
};

/** Trennt die Graph-Laufzeit von den Worker-eigenen Stores, damit neue Laufzeit-Felder nur in `TaskGraphRuntime` stehen. */
function runtimeFrom(stores: TaskRunWorkerStores, logger: ApplicationLogger): TaskGraphRuntime {
  const {taskStore: _taskStore, taskRunStore: _taskRunStore, ...runtime} = stores;
  return {...runtime, logger};
}

export async function executeQueuedTaskRun(
  ai: GenkitBeta,
  input: {
    teamId: string;
    run: TaskRunDocument;
    stores: TaskRunWorkerStores;
  },
  logger: ApplicationLogger,
): Promise<Result<void, NodeExecutionFailure>> {
  const {teamId, run, stores} = input;
  await stores.taskRunStore.markRunStarted(teamId, run.runId);
  const taskDefinition = await definitionFor(stores, teamId, run);
  return executeTaskGraph(ai, {
    taskDefinition,
    context: run.context,
    teamId,
    input: run.input,
    runId: run.runId,
  }, runtimeFrom(stores, logger))
    .map((output) => recordOutput(stores, teamId, run, output));
}

export async function continueApprovedTaskRun(
  ai: GenkitBeta,
  input: {
    teamId: string;
    run: TaskRunDocument;
    resumeState: TaskResumeState;
    responseOutputs: Record<string, NodeOutputValue>;
    stores: TaskRunWorkerStores;
  },
  logger: ApplicationLogger,
): Promise<Result<void, NodeExecutionFailure>> {
  const {teamId, run, stores} = input;
  await stores.taskRunStore.markRunStarted(teamId, run.runId);
  const taskDefinition = await definitionFor(stores, teamId, run);
  return resumeTaskGraph(
    ai,
    {taskDefinition, context: run.context, teamId, input: run.input, runId: run.runId},
    input.resumeState,
    input.responseOutputs,
    runtimeFrom(stores, logger),
  )
    .map((output) => recordOutput(stores, teamId, run, output));
}

/** Der Graph, mit dem der Lauf begonnen hat; ältere Läufe ohne Schnappschuss laden die Aufgabe. */
async function definitionFor(stores: TaskRunWorkerStores, teamId: string, run: TaskRunDocument) {
  return run.graphSnapshot ?? stores.taskStore.loadTask(teamId, run.taskId);
}

async function recordOutput(
  stores: TaskRunWorkerStores,
  teamId: string,
  run: TaskRunDocument,
  output: TaskGraphOutput,
) {
  if (output.status === "waitingForApproval") {
    await stores.taskRunStore.markRunWaitingForApproval(teamId, run, output);
    return;
  }
  await stores.taskRunStore.markRunSucceeded(teamId, run, output);
  await stores.stepJournal?.clear(teamId, run.runId);
}
