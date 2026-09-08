import {type GenkitBeta} from "genkit/beta";
import {type KnowledgeBaseStore} from
  "../../../../knowledge_base/domain/repositories/knowledge-base-store.js";
import {
  executeTaskGraph,
  resumeTaskGraph,
} from "./task-graph-runner.js";
import {
  type TaskResumeState,
  type NodeOutputValue,
} from "./task-definition.js";
import {type TaskStore} from "../../../domain/repositories/task-store.js";
import {type ObjectStore} from "../../../../files/domain/repositories/object-store.js";
import {type TeamFileStore} from "../../../../files/domain/repositories/team-file-store.js";
import {type TeamFileContentReader} from "../../../../files/domain/repositories/team-file-content-reader.js";
import {type TaskMessageSender} from "../../../domain/repositories/task-message-sender.js";
import {type ModelInference} from "../../../../machine_learning/domain/repositories/model-inference.js";
import {
  type TaskRunDocument,
  type TaskRunStore,
} from "../../../domain/repositories/task-run-store.js";
import {type GenkitLanguageModelResolver} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";

export type TaskRunWorkerStores = {
  taskStore: TaskStore;
  taskRunStore: TaskRunStore;
  objectStore: ObjectStore;
  knowledgeBaseStore: KnowledgeBaseStore;
  teamFileStore: TeamFileStore;
  fileContentReader: TeamFileContentReader;
  messageSender: TaskMessageSender;
  modelInference: ModelInference;
  languageModelResolver?: GenkitLanguageModelResolver;
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
    teamFileStore: stores.teamFileStore,
    fileContentReader: stores.fileContentReader,
    messageSender: stores.messageSender,
    modelInference: stores.modelInference,
    languageModelResolver: stores.languageModelResolver,
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
    responseOutputs: Record<string, NodeOutputValue>;
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
    input.responseOutputs,
    {
      objectStore: stores.objectStore,
      knowledgeBaseStore: stores.knowledgeBaseStore,
      teamFileStore: stores.teamFileStore,
      fileContentReader: stores.fileContentReader,
      messageSender: stores.messageSender,
      modelInference: stores.modelInference,
      languageModelResolver: stores.languageModelResolver,
    },
  );
  if (output.status === "waitingForApproval") {
    await stores.taskRunStore.markRunWaitingForApproval(teamId, run, output);
    return;
  }
  await stores.taskRunStore.markRunSucceeded(teamId, run, output);
}
