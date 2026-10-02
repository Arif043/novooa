import {type TaskGraphRuntime} from "./task-graph-runtime.js";
import {type GenkitBeta} from "genkit/beta";
import {
  executeTaskGraph,
  resumeTaskGraph,
} from "./task-graph-runner.js";
import {
  type TaskResumeState,
  type NodeOutputValue,
} from "./task-definition.js";
import {type TaskStore} from "../../../domain/repositories/task-store.js";
import {
  type TaskRunDocument,
  type TaskRunStore,
} from "../../../domain/repositories/task-run-store.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

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
) {
  const {teamId, run, stores} = input;
  await stores.taskRunStore.markRunStarted(teamId, run.runId);
  const taskDefinition = await stores.taskStore.loadTask(teamId, run.taskId);
  const output = await executeTaskGraph(ai, {
    taskDefinition,
    context: run.context,
    teamId,
    input: run.input,
  }, runtimeFrom(stores, logger));
  if (output.status === "waitingForApproval") {
    await stores.taskRunStore.markRunWaitingForApproval(teamId, run, output);
    return;
  }
  await stores.taskRunStore.markRunSucceeded(teamId, run, output);
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
) {
  const {teamId, run, stores} = input;
  await stores.taskRunStore.markRunStarted(teamId, run.runId);
  const taskDefinition = await stores.taskStore.loadTask(teamId, run.taskId);
  const output = await resumeTaskGraph(
    ai,
    {taskDefinition, context: run.context, teamId, input: run.input},
    input.resumeState,
    input.responseOutputs,
    runtimeFrom(stores, logger),
  );
  if (output.status === "waitingForApproval") {
    await stores.taskRunStore.markRunWaitingForApproval(teamId, run, output);
    return;
  }
  await stores.taskRunStore.markRunSucceeded(teamId, run, output);
}
