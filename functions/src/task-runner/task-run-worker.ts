import {type GenkitBeta} from "genkit/beta";
import {type KnowledgeBaseStore} from
  "../domain/repositories/knowledge-base-store.js";
import {
  executeTaskGraph,
  resumeTaskGraph,
} from "./task-graph-runner.js";
import {
  type TaskResumeState,
} from "./task-definition.js";
import {type TaskStore} from "../domain/repositories/task-store.js";
import {type ObjectStore} from "../domain/repositories/object-store.js";
import {
  type TaskRunDocument,
  type TaskRunStore,
} from "../domain/repositories/task-run-store.js";

export type TaskRunWorkerStores = {
  taskStore: TaskStore;
  taskRunStore: TaskRunStore;
  objectStore: ObjectStore;
  knowledgeBaseStore: KnowledgeBaseStore;
};

export async function executeQueuedTaskRun(
  ai: GenkitBeta,
  input: {
    teamId: string;
    run: TaskRunDocument;
    stores: TaskRunWorkerStores;
  },
) {
  const {teamId, run, stores} = input;
  await stores.taskRunStore.markRunStarted(teamId, run.runId);
  const taskDefinition = await stores.taskStore.loadTask(teamId, run.taskId);
  const output = await executeTaskGraph(ai, {
    taskDefinition,
    context: run.context,
    teamId,
    input: run.input,
  }, {
    objectStore: stores.objectStore,
    knowledgeBaseStore: stores.knowledgeBaseStore,
  });
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
    approvedOutput: string;
    stores: TaskRunWorkerStores;
  },
) {
  const {teamId, run, stores} = input;
  await stores.taskRunStore.markRunStarted(teamId, run.runId);
  const taskDefinition = await stores.taskStore.loadTask(teamId, run.taskId);
  const output = await resumeTaskGraph(
    ai,
    {taskDefinition, context: run.context, teamId, input: run.input},
    input.resumeState,
    input.approvedOutput,
    {
      objectStore: stores.objectStore,
      knowledgeBaseStore: stores.knowledgeBaseStore,
    },
  );
  if (output.status === "waitingForApproval") {
    await stores.taskRunStore.markRunWaitingForApproval(teamId, run, output);
    return;
  }
  await stores.taskRunStore.markRunSucceeded(teamId, run, output);
}
