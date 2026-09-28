import path from "node:path";
import {LocalObjectStore} from "../../features/files/infrastructure/local/local-object-store.js";
import {LocalFileResourceHttpHandler} from "../../features/files/infrastructure/local/local-file-resource-http-handler.js";
import {LocalTeamFileStore} from "../../features/files/infrastructure/local/local-team-file-store.js";
import {LocalKnowledgeNoteHttpHandler} from "../../features/knowledge_base/infrastructure/local/local-knowledge-note-http-handler.js";
import {SQLiteKnowledgeBaseStore} from "../../features/knowledge_base/infrastructure/local/sqlite-knowledge-base-store.js";
import {createLocalSidecarModelInference} from "../../features/machine_learning/infrastructure/local/local-sidecar-model-inference.js";
import {LocalModelArtifactPublisher} from "../../features/machine_learning/infrastructure/local/local-model-artifact-publisher.js";
import {LocalModelArtifactUploadStore} from "../../features/machine_learning/infrastructure/local/local-model-artifact-upload-store.js";
import {LocalModelCatalogHttpHandler} from "../../features/machine_learning/infrastructure/local/local-model-catalog-http-handler.js";
import {FirebaseRuntimeModelCatalog} from "../../features/machine_learning/infrastructure/local/firebase-runtime-model-catalog.js";
import {HuggingFaceModelArtifactDownloader} from "../../features/machine_learning/infrastructure/local/hugging-face-model-artifact-downloader.js";
import {SQLiteModelCatalog} from "../../features/machine_learning/infrastructure/local/sqlite-model-catalog.js";
import {
  PythonModelContractValidator,
  UnavailablePythonModelContractValidator,
} from "../../features/machine_learning/infrastructure/local/python-model-contract-validator.js";
import {UnavailableLocalModelInference} from "../../features/machine_learning/infrastructure/local/unavailable-local-model-inference.js";
import {SQLiteTeamContextStore} from "../../features/teams/infrastructure/local/sqlite-team-context-store.js";
import {LocalTaskMessageSender} from "../../features/task_execution/infrastructure/local/local-task-message-sender.js";
import {LocalMailRelayHttpHandler} from "../../features/communication/infrastructure/local/local-mail-relay-http-handler.js";
import {LocalMailRelayEventProcessor} from "../../features/communication/infrastructure/local/local-mail-relay-event-processor.js";
import {RuntimeMailRelayWorker} from "../../features/communication/infrastructure/local/polling-runtime-mail-relay-worker.js";
import {
  HttpRuntimeMailRelayClient,
  type RuntimeMailRelayClient,
  UnavailableRuntimeMailRelayClient,
} from "../../features/communication/infrastructure/local/runtime-mail-relay-client.js";
import {SQLiteInboundChannelMessageStore} from "../../features/communication/infrastructure/local/sqlite-inbound-channel-message-store.js";
import {LocalPushDeviceHttpHandler} from "../../features/notifications/infrastructure/local/local-push-device-http-handler.js";
import {
  HttpRuntimePushRelayClient,
  type RuntimePushRelayClient,
  UnavailableRuntimePushRelayClient,
} from "../../features/notifications/infrastructure/local/runtime-push-relay-client.js";
import {LocalTaskRunApprovalPushNotifier} from "../../features/notifications/infrastructure/local/local-task-run-approval-push-notifier.js";
import {LocalTeamNotificationSender} from "../../features/notifications/infrastructure/local/local-team-notification-sender.js";
import {LocalTaskActivityHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-activity-http-handler.js";
import {LocalTaskDefinitionHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-definition-http-handler.js";
import {LocalTaskRunHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-run-http-handler.js";
import {TaskRunQueueWorker} from "../../features/task_execution/infrastructure/local/task-run-queue-worker.js";
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
import {LocalRuntimeAccessCredentialStore} from "./local-runtime-access-credential-store.js";
import {LocalRuntimeSessionStore} from "./local-runtime-session-store.js";
import {LocalRuntimeLoginHttpHandler} from "./local-runtime-login-http-handler.js";
import {LocalRuntimeSetupHttpHandler} from "./local-runtime-setup-http-handler.js";
import {type LocalRuntimeSetupCode} from "./local-runtime-setup-code.js";
import {LocalRuntimeSessionAuthMiddleware} from "./local-runtime-session-auth-middleware.js";
import {LocalRuntimeRealtimeNotifier} from "./local-runtime-realtime-notifier.js";
import {LocalRuntimeRealtimeTicketStore} from "./local-runtime-realtime-ticket-store.js";
import {LocalRuntimeRealtimeTicketHttpHandler} from "./local-runtime-realtime-ticket-http-handler.js";
import {type LocalRuntimeWorkspace} from "./local-runtime-workspace.js";
import {type SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";
import {type SignedRuntimeLicense} from "../../features/licensing/domain/entities/runtime-license-lease.js";
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
import {type DocumentStore} from "../../features/data/domain/repositories/document-store.js";
import {SQLiteDocumentStore} from "../../features/data/infrastructure/local/sqlite-document-store.js";
import {LocalDataHttpHandler} from "../../features/data/infrastructure/local/local-data-http-handler.js";
import {
  RuntimeFirebaseSession,
  runtimeFirebaseConfigurationFromEnvironment,
} from "../../features/licensing/infrastructure/local/runtime-firebase-session.js";
import {type RuntimeLicenseActivation} from "../../features/licensing/domain/entities/runtime-license-activation.js";
import {type TaskWorkflow} from "../../features/task_execution/domain/usecases/task-workflow.js";

export type LocalRuntimeComposition = {
  requestHandler: LocalRuntimeRequestHandler;
  setupHandler: LocalRuntimeRequestHandler;
  taskRunWorker: TaskRunQueueWorker;
  taskTriggerWorker: PollingTaskTriggerWorker;
  mailRelayWorker: RuntimeMailRelayWorker | undefined;
  firebaseSession: RuntimeFirebaseSession | undefined;
  applicationLogger: LocalApplicationLogger;
  languageModelSecretStore: LocalLanguageModelSecretStore;
  documentStore: DocumentStore;
  realtimeNotifier: LocalRuntimeRealtimeNotifier;
  realtimeTicketStore: LocalRuntimeRealtimeTicketStore;
};

export type LocalRuntimeCompositionOptions = {
  database: SqliteLocalSqlDatabase;
  runtimeRoot: string;
  workspace: LocalRuntimeWorkspace;
  localMasterKey: string;
  /** Prozessweit, im Entrypoint erzeugt — beide Setup-Wege teilen ihn. */
  setupCode: LocalRuntimeSetupCode;
  isLicenseActive?: () => boolean;
  signedLicense: () => SignedRuntimeLicense | null;
  activeLicenseActivation: () => RuntimeLicenseActivation | null;
};

export function createLocalRuntimeComposition(
  options: LocalRuntimeCompositionOptions,
): LocalRuntimeComposition {
  const realtimeNotifier = new LocalRuntimeRealtimeNotifier();
  const realtimeTicketStore = new LocalRuntimeRealtimeTicketStore();
  const activityStore = new SQLiteActivityStore(options.database);
  const applicationLogStore = new SQLiteLocalApplicationLogStore(options.database);
  const applicationLogger = new LocalApplicationLogger(
    applicationLogStore,
    options.workspace.teamId,
  );
  const pushRelay = pushRelayFor();
  const mailRelay = mailRelayFor();
  const firebaseSession = firebaseSessionFor();
  const taskRunStore = new SQLiteTaskRunStore(
    options.database,
    activityStore,
    new LocalTaskRunApprovalPushNotifier(options.signedLicense, pushRelay, applicationLogger),
  );
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
  const documentStore = new SQLiteDocumentStore(options.database);
  let taskWorkflow: TaskWorkflow | undefined;
  const taskRunWorker = new TaskRunQueueWorker(
    jobStore,
    async (input) => {
      if (taskWorkflow === undefined) throw new Error("Die Aufgabenverarbeitung ist nicht initialisiert.");
      await taskWorkflow.dispatch(input);
    },
    {
      canProcess: options.isLicenseActive,
      onFailure: (job, error) => applicationLogger.exception(
        "task_run_worker.job_failed",
        error,
        {jobId: job.jobId, runId: job.runId, teamId: job.teamId},
      ),
      onDrainFailure: (error) => applicationLogger.exception(
        "task_run_worker.drain_failed", error, {teamId: options.workspace.teamId},
      ),
      notifier: realtimeNotifier,
    },
  );
  const taskRunDispatcher = new SQLiteTaskRunDispatcher(jobStore, taskRunWorker);
  taskWorkflow = createTaskWorkflow(
    options,
    taskRunStore,
    teamFileStore,
    taskRunDispatcher,
    applicationLogger,
    new SQLiteLanguageModelCatalog(options.database, languageModelSecretStore),
    documentStore,
    mailRelay,
    pushRelay,
  );
  const mailRelayWorker = mailRelayWorkerFor(
    options, mailRelay, taskStore, taskRunStore, taskRunDispatcher, applicationLogger,
  );
  applicationLogger.info("local_runtime.workspace_activated", {
    teamId: options.workspace.teamId,
  });
  const sessionStore = new LocalRuntimeSessionStore(options.database);
  const credentialStore = new LocalRuntimeAccessCredentialStore(options.database);
  const router = new LocalRuntimeRequestRouter([
    // Auf dem regulären Port ersetzt der Kopplungscode die Session — sonst
    // liesse sich das Passwort nie setzen, das man für eine Session
    // bräuchte. Steht deshalb auch in `unauthenticatedPaths` der Session-Middleware.
    new LocalRuntimeSetupHttpHandler({
      credentials: credentialStore,
      setupCode: options.setupCode,
      requiresCode: true,
    }),
    new LocalRuntimeLoginHttpHandler(credentialStore, sessionStore),
    new LocalRuntimeRealtimeTicketHttpHandler(realtimeTicketStore),
    new LocalTaskRunHttpHandler(taskWorkflow, options.workspace.userId, applicationLogger, realtimeNotifier),
    new LocalPushDeviceHttpHandler(options.signedLicense, pushRelay),
    new LocalMailRelayHttpHandler(options.signedLicense, mailRelay),
    new LocalTaskDefinitionHttpHandler(
      taskDefinitionStore,
      options.workspace.teamId,
      options.workspace.userId,
      realtimeNotifier,
    ),
    new LocalLanguageModelHttpHandler(languageModelStore, options.workspace.teamId, realtimeNotifier),
    new LocalDataHttpHandler(documentStore, options.workspace.teamId),
    new LocalModelCatalogHttpHandler(
      new SQLiteModelCatalog(options.database),
      new LocalModelArtifactPublisher(options.runtimeRoot),
      new LocalModelArtifactUploadStore(options.runtimeRoot),
      options.workspace.teamId,
      modelContractValidatorFor(),
      applicationLogger,
      realtimeNotifier,
      firebaseSession === undefined ? undefined : new FirebaseRuntimeModelCatalog(firebaseSession),
      new HuggingFaceModelArtifactDownloader(
        path.join(options.runtimeRoot, "model-cache"),
        process.env.HF_TOKEN?.trim() || undefined,
      ),
    ),
    new LocalTaskActivityHttpHandler(options.database, options.workspace.teamId),
    new LocalApplicationLogHttpHandler(applicationLogStore, options.workspace.teamId, realtimeNotifier),
    new LocalKnowledgeNoteHttpHandler(options.database, options.workspace.teamId, realtimeNotifier),
    new LocalTaskTriggerHttpHandler(options.database, options.workspace.teamId, options.workspace.userId, realtimeNotifier),
    new LocalFileResourceHttpHandler(
      options.database, teamFileStore, options.workspace.teamId, options.workspace.userId, realtimeNotifier,
    ),
  ]);
  return {
    requestHandler: new LocalRuntimeSessionAuthMiddleware(sessionStore, router),
    // Der loopback-gebundene Setup-Port braucht keinen Code: dort ist die
    // Netzwerkgrenze selbst der Schutz. Bleibt als Rückfallweg bestehen,
    // falls der Code verloren geht.
    setupHandler: new LocalRuntimeSetupHttpHandler({
      credentials: credentialStore,
      setupCode: options.setupCode,
      requiresCode: false,
    }),
    taskRunWorker,
    taskTriggerWorker: new PollingTaskTriggerWorker(
      () => runDueTaskTriggers(new Date(), {
        triggerStore: new SQLiteTaskTriggerStore(options.database),
        taskStore,
        taskRunStore,
        taskRunDispatcher,
      }),
      {
        canProcess: options.isLicenseActive,
        onFailure: (error) => applicationLogger.exception(
          "task_trigger_worker.failed",
          error,
          {teamId: options.workspace.teamId},
        ),
        notifier: realtimeNotifier,
      },
    ),
    mailRelayWorker,
    firebaseSession,
    applicationLogger,
    languageModelSecretStore,
    documentStore,
    realtimeNotifier,
    realtimeTicketStore,
  };
}

function pushRelayFor() {
  const endpoint = process.env.LOCAL_RUNTIME_PUSH_RELAY_URL?.trim();
  return endpoint
    ? new HttpRuntimePushRelayClient(endpoint)
    : new UnavailableRuntimePushRelayClient();
}

function mailRelayFor(): RuntimeMailRelayClient {
  const endpoint = process.env.LOCAL_RUNTIME_MAIL_RELAY_URL?.trim();
  return endpoint
    ? new HttpRuntimeMailRelayClient(endpoint)
    : new UnavailableRuntimeMailRelayClient();
}

function mailRelayWorkerFor(
  options: LocalRuntimeCompositionOptions,
  relay: RuntimeMailRelayClient,
  taskStore: SQLiteTaskStore,
  taskRunStore: SQLiteTaskRunStore,
  taskRunDispatcher: SQLiteTaskRunDispatcher,
  logger: LocalApplicationLogger,
): RuntimeMailRelayWorker | undefined {
  if (!process.env.LOCAL_RUNTIME_MAIL_RELAY_URL?.trim()) return undefined;
  return new RuntimeMailRelayWorker(
    options.signedLicense, relay,
    new LocalMailRelayEventProcessor(
      new SQLiteInboundChannelMessageStore(options.database),
      {
        triggerStore: new SQLiteTaskTriggerStore(options.database), taskStore, taskRunStore,
        taskRunDispatcher,
      }, options.workspace.teamId, logger,
    ), logger, {
      canProcess: options.isLicenseActive,
      onFailure: (error) => logger.exception(
        "local_mail_relay.processing_failed", error, {teamId: options.workspace.teamId},
      ),
    },
  );
}

function firebaseSessionFor(): RuntimeFirebaseSession | undefined {
  const configuration = runtimeFirebaseConfigurationFromEnvironment();
  return configuration ? new RuntimeFirebaseSession(configuration) : undefined;
}

function createTaskWorkflow(
  options: LocalRuntimeCompositionOptions,
  taskRunStore: SQLiteTaskRunStore,
  teamFileStore: LocalTeamFileStore,
  taskRunDispatcher: SQLiteTaskRunDispatcher,
  logger: LocalApplicationLogger,
  languageModelCatalog: SQLiteLanguageModelCatalog,
  documentStore: DocumentStore,
  mailRelay: RuntimeMailRelayClient,
  pushRelay: RuntimePushRelayClient,
) {
  return createGenkitTaskWorkflow({
    taskStore: new SQLiteTaskStore(options.database),
    taskRunStore,
    taskRunDispatcher,
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
      messageSender: new LocalTaskMessageSender(options.signedLicense, mailRelay),
      documentStore,
      modelInference: modelInferenceFor(options),
      teamNotificationSender: new LocalTeamNotificationSender(
        options.signedLicense,
        pushRelay,
        logger,
      ),
      languageModelResolver: new CatalogGenkitLanguageModelResolver(
        languageModelCatalog,
      ),
    },
  });
}

function modelContractValidatorFor() {
  const sidecarUrl = process.env.PYTHON_INFERENCE_SIDECAR_URL?.trim();
  return sidecarUrl
    ? new PythonModelContractValidator(sidecarUrl)
    : new UnavailablePythonModelContractValidator();
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
