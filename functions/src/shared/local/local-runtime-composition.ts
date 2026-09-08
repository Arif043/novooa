import {LocalObjectStore} from "../../features/files/infrastructure/local/local-object-store.js";
import {LocalTeamFileStore} from "../../features/files/infrastructure/local/local-team-file-store.js";
import {SQLiteKnowledgeBaseStore} from "../../features/knowledge_base/infrastructure/local/sqlite-knowledge-base-store.js";
import {createLocalSidecarModelInference} from "../../features/machine_learning/infrastructure/local/local-sidecar-model-inference.js";
import {UnavailableLocalModelInference} from "../../features/machine_learning/infrastructure/local/unavailable-local-model-inference.js";
import {SQLiteTeamContextStore} from "../../features/teams/infrastructure/local/sqlite-team-context-store.js";
import {LocalTaskMessageSender} from "../../features/task_execution/infrastructure/local/local-task-message-sender.js";
import {LocalTaskRunHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-run-http-handler.js";
import {PollingTaskRunWorker} from "../../features/task_execution/infrastructure/local/polling-task-run-worker.js";
import {SQLiteActivityStore} from "../../features/task_execution/infrastructure/local/sqlite-activity-store.js";
import {SQLiteTaskRunDispatcher} from "../../features/task_execution/infrastructure/local/sqlite-task-run-dispatcher.js";
import {SQLiteTaskRunJobStore} from "../../features/task_execution/infrastructure/local/sqlite-task-run-job-store.js";
import {SQLiteTaskRunStore} from "../../features/task_execution/infrastructure/local/sqlite-task-run-store.js";
import {SQLiteTaskStore} from "../../features/task_execution/infrastructure/local/sqlite-task-store.js";
import {createGenkitTaskWorkflow} from "../../features/task_execution/infrastructure/genkit/task-workflow.js";
import {type LocalRuntimeRequestHandler} from "./local-runtime-http-server.js";
import {type LocalRuntimeWorkspace} from "./local-runtime-workspace.js";
import {type SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";

export type LocalRuntimeComposition = {
  requestHandler: LocalRuntimeRequestHandler;
  taskRunWorker: PollingTaskRunWorker;
};

export type LocalRuntimeCompositionOptions = {
  database: SqliteLocalSqlDatabase;
  runtimeRoot: string;
  workspace: LocalRuntimeWorkspace;
};

export function createLocalRuntimeComposition(
  options: LocalRuntimeCompositionOptions,
): LocalRuntimeComposition {
  const activityStore = new SQLiteActivityStore(options.database);
  const taskRunStore = new SQLiteTaskRunStore(options.database, activityStore);
  const teamFileStore = new LocalTeamFileStore(options.database, options.runtimeRoot);
  const jobStore = new SQLiteTaskRunJobStore(options.database);
  const taskWorkflow = createTaskWorkflow(options, taskRunStore, teamFileStore, jobStore);
  return {
    requestHandler: new LocalTaskRunHttpHandler(taskWorkflow, options.workspace.userId),
    taskRunWorker: new PollingTaskRunWorker(jobStore, (input) => taskWorkflow.dispatch(input)),
  };
}

function createTaskWorkflow(
  options: LocalRuntimeCompositionOptions,
  taskRunStore: SQLiteTaskRunStore,
  teamFileStore: LocalTeamFileStore,
  jobStore: SQLiteTaskRunJobStore,
) {
  return createGenkitTaskWorkflow({
    taskStore: new SQLiteTaskStore(options.database),
    taskRunStore,
    taskRunDispatcher: new SQLiteTaskRunDispatcher(jobStore),
    teamContextStore: new SQLiteTeamContextStore(options.database),
    teamFileStore,
    workerStores: {
      taskStore: new SQLiteTaskStore(options.database),
      taskRunStore,
      objectStore: new LocalObjectStore(options.runtimeRoot),
      knowledgeBaseStore: new SQLiteKnowledgeBaseStore(options.database),
      teamFileStore,
      fileContentReader: teamFileStore,
      messageSender: new LocalTaskMessageSender(),
      modelInference: modelInferenceFor(options),
    },
  });
}

function modelInferenceFor(options: LocalRuntimeCompositionOptions) {
  const sidecarUrl = process.env.PYTHON_INFERENCE_SIDECAR_URL?.trim();
  if (sidecarUrl) {
    return createLocalSidecarModelInference(
      options.database,
      options.runtimeRoot,
      sidecarUrl,
    );
  }
  return new UnavailableLocalModelInference();
}
