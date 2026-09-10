import {LocalObjectStore} from "../../features/files/infrastructure/local/local-object-store.js";
import {LocalFileResourceHttpHandler} from "../../features/files/infrastructure/local/local-file-resource-http-handler.js";
import {LocalTeamFileStore} from "../../features/files/infrastructure/local/local-team-file-store.js";
import {LocalKnowledgeNoteHttpHandler} from "../../features/knowledge_base/infrastructure/local/local-knowledge-note-http-handler.js";
import {SQLiteKnowledgeBaseStore} from "../../features/knowledge_base/infrastructure/local/sqlite-knowledge-base-store.js";
import {createLocalSidecarModelInference} from "../../features/machine_learning/infrastructure/local/local-sidecar-model-inference.js";
import {UnavailableLocalModelInference} from "../../features/machine_learning/infrastructure/local/unavailable-local-model-inference.js";
import {SQLiteTeamContextStore} from "../../features/teams/infrastructure/local/sqlite-team-context-store.js";
import {LocalTaskMessageSender} from "../../features/task_execution/infrastructure/local/local-task-message-sender.js";
import {LocalTaskActivityHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-activity-http-handler.js";
import {LocalTaskDefinitionHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-definition-http-handler.js";
import {LocalTaskRunHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-run-http-handler.js";
import {PollingTaskRunWorker} from "../../features/task_execution/infrastructure/local/polling-task-run-worker.js";
import {SQLiteActivityStore} from "../../features/task_execution/infrastructure/local/sqlite-activity-store.js";
import {SQLiteTaskRunDispatcher} from "../../features/task_execution/infrastructure/local/sqlite-task-run-dispatcher.js";
import {SQLiteTaskRunJobStore} from "../../features/task_execution/infrastructure/local/sqlite-task-run-job-store.js";
import {SQLiteTaskRunStore} from "../../features/task_execution/infrastructure/local/sqlite-task-run-store.js";
import {SQLiteTaskStore} from "../../features/task_execution/infrastructure/local/sqlite-task-store.js";
import {SQLiteTaskDefinitionStore} from "../../features/task_execution/infrastructure/local/sqlite-task-definition-store.js";
import {runDueTaskTriggers} from "../../features/scheduling/domain/usecases/run-due-task-triggers.js";
import {LocalTaskTriggerHttpHandler} from "../../features/scheduling/infrastructure/local/local-task-trigger-http-handler.js";
import {PollingTaskTriggerWorker} from "../../features/scheduling/infrastructure/local/polling-task-trigger-worker.js";
import {SQLiteTaskTriggerStore} from "../../features/scheduling/infrastructure/local/sqlite-task-trigger-store.js";
import {createGenkitTaskWorkflow} from "../../features/task_execution/infrastructure/genkit/task-workflow.js";
import {type LocalRuntimeRequestHandler} from "./local-runtime-http-server.js";
import {LocalRuntimeRequestRouter} from "./local-runtime-request-router.js";
import {type LocalRuntimeWorkspace} from "./local-runtime-workspace.js";
import {type SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";
import {LocalApplicationLogHttpHandler} from "../logging/local-application-log-http-handler.js";
import {LocalApplicationLogger} from "../logging/local-application-logger.js";
import {SQLiteLocalApplicationLogStore} from "../logging/sqlite-local-application-log-store.js";
import {CredentialCipher} from "../../features/communication/infrastructure/security/credential-cipher.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "../../features/language_models/infrastructure/local/encrypted-sqlite-language-model-secret-store.js";
import {type LocalLanguageModelSecretStore} from "../../features/language_models/infrastructure/local/local-language-model-secret-store.js";
import {LocalLanguageModelHttpHandler} from "../../features/language_models/infrastructure/local/local-language-model-http-handler.js";
import {SQLiteLanguageModelConfigurationStore} from "../../features/language_models/infrastructure/local/sqlite-language-model-configuration-store.js";
import {SQLiteLanguageModelCatalog} from "../../features/language_models/infrastructure/local/sqlite-language-model-catalog.js";
import {CatalogGenkitLanguageModelResolver} from "../../features/language_models/infrastructure/genkit/genkit-language-model-resolver.js";

export type LocalRuntimeComposition = {
  requestHandler: LocalRuntimeRequestHandler;
  taskRunWorker: PollingTaskRunWorker;
  taskTriggerWorker: PollingTaskTriggerWorker;
  applicationLogger: LocalApplicationLogger;
  languageModelSecretStore: LocalLanguageModelSecretStore;
};

export type LocalRuntimeCompositionOptions = {
  database: SqliteLocalSqlDatabase;
  runtimeRoot: string;
  workspace: LocalRuntimeWorkspace;
  localMasterKey: string;
  isLicenseActive?: () => boolean;
};

export function createLocalRuntimeComposition(
  options: LocalRuntimeCompositionOptions,
): LocalRuntimeComposition {
  const activityStore = new SQLiteActivityStore(options.database);
  const taskRunStore = new SQLiteTaskRunStore(options.database, activityStore);
  const teamFileStore = new LocalTeamFileStore(options.database, options.runtimeRoot);
  const jobStore = new SQLiteTaskRunJobStore(options.database);
  const taskStore = new SQLiteTaskStore(options.database);
  const taskDefinitionStore = new SQLiteTaskDefinitionStore(options.database);
  const languageModelSecretStore = new EncryptedSQLiteLanguageModelSecretStore(
    options.database,
    new CredentialCipher(options.localMasterKey, "LOCAL_RUNTIME_MASTER_KEY"),
  );
  const languageModelStore = new SQLiteLanguageModelConfigurationStore(
    options.database,
    languageModelSecretStore,
  );
  const applicationLogStore = new SQLiteLocalApplicationLogStore(options.database);
  const applicationLogger = new LocalApplicationLogger(
    applicationLogStore,
    options.workspace.teamId,
  );
  const taskWorkflow = createTaskWorkflow(
    options,
    taskRunStore,
    teamFileStore,
    jobStore,
    applicationLogger,
    new SQLiteLanguageModelCatalog(options.database, languageModelSecretStore),
  );
  applicationLogger.info("local_runtime.workspace_activated", {
    teamId: options.workspace.teamId,
  });
  return {
    requestHandler: new LocalRuntimeRequestRouter([
      new LocalTaskRunHttpHandler(taskWorkflow, options.workspace.userId),
      new LocalTaskDefinitionHttpHandler(
        taskDefinitionStore,
        options.workspace.teamId,
        options.workspace.userId,
      ),
      new LocalLanguageModelHttpHandler(languageModelStore, options.workspace.teamId),
      new LocalTaskActivityHttpHandler(options.database, options.workspace.teamId),
      new LocalApplicationLogHttpHandler(applicationLogStore, options.workspace.teamId),
      new LocalKnowledgeNoteHttpHandler(options.database, options.workspace.teamId),
      new LocalTaskTriggerHttpHandler(options.database, options.workspace.teamId, options.workspace.userId),
      new LocalFileResourceHttpHandler(options.database, teamFileStore, options.workspace.teamId, options.workspace.userId),
    ]),
    taskRunWorker: new PollingTaskRunWorker(
      jobStore,
      (input) => taskWorkflow.dispatch(input),
      {
        canProcess: options.isLicenseActive,
        onFailure: (job, error) => applicationLogger.exception(
          "task_run_worker.job_failed",
          error,
          {jobId: job.jobId, runId: job.runId, teamId: job.teamId},
        ),
      },
    ),
    taskTriggerWorker: new PollingTaskTriggerWorker(
      () => runDueTaskTriggers(new Date(), {
        triggerStore: new SQLiteTaskTriggerStore(options.database),
        taskStore,
        taskRunStore,
        taskRunDispatcher: new SQLiteTaskRunDispatcher(jobStore),
      }),
      {
        canProcess: options.isLicenseActive,
        onFailure: (error) => applicationLogger.exception(
          "task_trigger_worker.failed",
          error,
          {teamId: options.workspace.teamId},
        ),
      },
    ),
    applicationLogger,
    languageModelSecretStore,
  };
}

function createTaskWorkflow(
  options: LocalRuntimeCompositionOptions,
  taskRunStore: SQLiteTaskRunStore,
  teamFileStore: LocalTeamFileStore,
  jobStore: SQLiteTaskRunJobStore,
  logger: LocalApplicationLogger,
  languageModelCatalog: SQLiteLanguageModelCatalog,
) {
  return createGenkitTaskWorkflow({
    taskStore: new SQLiteTaskStore(options.database),
    taskRunStore,
    taskRunDispatcher: new SQLiteTaskRunDispatcher(jobStore),
    teamContextStore: new SQLiteTeamContextStore(options.database),
    teamFileStore,
    logger,
    workerStores: {
      taskStore: new SQLiteTaskStore(options.database),
      taskRunStore,
      objectStore: new LocalObjectStore(options.runtimeRoot),
      knowledgeBaseStore: new SQLiteKnowledgeBaseStore(options.database),
      teamFileStore,
      fileContentReader: teamFileStore,
      messageSender: new LocalTaskMessageSender(),
      modelInference: modelInferenceFor(options),
      languageModelResolver: new CatalogGenkitLanguageModelResolver(
        languageModelCatalog,
      ),
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
