import path from "node:path";
import {type RuntimeDatabase} from "../../db/database.js";
import {LocalMailRelayEventProcessor} from "../../features/communication/infrastructure/local/local-mail-relay-event-processor.js";
import {LocalMailRelayHttpHandler} from "../../features/communication/infrastructure/local/local-mail-relay-http-handler.js";
import {RuntimeMailRelayWorker} from "../../features/communication/infrastructure/local/polling-runtime-mail-relay-worker.js";
import {
  HttpRuntimeMailRelayClient,
  type RuntimeMailRelayClient,
  UnavailableRuntimeMailRelayClient,
} from "../../features/communication/infrastructure/local/runtime-mail-relay-client.js";
import {SQLiteInboundChannelMessageStore} from "../../features/communication/infrastructure/local/sqlite-inbound-channel-message-store.js";
import {type DocumentStore} from "../../features/data/domain/repositories/document-store.js";
import {LocalDataHttpHandler} from "../../features/data/infrastructure/local/local-data-http-handler.js";
import {SQLiteDocumentStore} from "../../features/data/infrastructure/local/sqlite-document-store.js";
import {LocalFileResourceHttpHandler} from "../../features/files/infrastructure/local/local-file-resource-http-handler.js";
import {LocalObjectStore} from "../../features/files/infrastructure/local/local-object-store.js";
import {LocalTeamFileStore} from "../../features/files/infrastructure/local/local-team-file-store.js";
import {createLocalKnowledgeBaseAssistant} from "../../features/knowledge_base/infrastructure/local/local-knowledge-base-assistant.js";
import {LocalKnowledgeNoteHttpHandler} from "../../features/knowledge_base/infrastructure/local/local-knowledge-note-http-handler.js";
import {SQLiteKnowledgeBaseStore} from "../../features/knowledge_base/infrastructure/local/sqlite-knowledge-base-store.js";
import {CatalogGenkitLanguageModelResolver} from "../../features/language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "../../features/language_models/infrastructure/local/encrypted-sqlite-language-model-secret-store.js";
import {LocalLanguageModelDefaultsHttpHandler} from "../../features/language_models/infrastructure/local/local-language-model-defaults-http-handler.js";
import {LocalLanguageModelHttpHandler} from "../../features/language_models/infrastructure/local/local-language-model-http-handler.js";
import {type LocalLanguageModelSecretStore} from "../../features/language_models/infrastructure/local/local-language-model-secret-store.js";
import {SQLiteLanguageModelCatalog} from "../../features/language_models/infrastructure/local/sqlite-language-model-catalog.js";
import {SQLiteLanguageModelConfigurationStore} from "../../features/language_models/infrastructure/local/sqlite-language-model-configuration-store.js";
import {SQLiteLanguageModelDefaultsStore} from "../../features/language_models/infrastructure/local/sqlite-language-model-defaults-store.js";
import {type RuntimeLicenseActivation} from "../../features/licensing/domain/entities/runtime-license-activation.js";
import {type SignedRuntimeLicense} from "../../features/licensing/domain/entities/runtime-license-lease.js";
import {
  RuntimeFirebaseSession,
  runtimeFirebaseConfigurationFromEnvironment,
} from "../../features/licensing/infrastructure/local/runtime-firebase-session.js";
import {FirebaseRuntimeModelCatalog} from "../../features/machine_learning/infrastructure/local/firebase-runtime-model-catalog.js";
import {HuggingFaceModelArtifactDownloader} from "../../features/machine_learning/infrastructure/local/hugging-face-model-artifact-downloader.js";
import {LocalModelArtifactPublisher} from "../../features/machine_learning/infrastructure/local/local-model-artifact-publisher.js";
import {LocalModelArtifactUploadStore} from "../../features/machine_learning/infrastructure/local/local-model-artifact-upload-store.js";
import {LocalModelCatalogHttpHandler} from "../../features/machine_learning/infrastructure/local/local-model-catalog-http-handler.js";
import {createLocalSidecarModelInference} from "../../features/machine_learning/infrastructure/local/local-sidecar-model-inference.js";
import {
  PythonModelContractValidator,
  UnavailablePythonModelContractValidator,
} from "../../features/machine_learning/infrastructure/local/python-model-contract-validator.js";
import {SQLiteModelCatalog} from "../../features/machine_learning/infrastructure/local/sqlite-model-catalog.js";
import {UnavailableLocalModelInference} from "../../features/machine_learning/infrastructure/local/unavailable-local-model-inference.js";
import {LocalPushDeviceHttpHandler} from "../../features/notifications/infrastructure/local/local-push-device-http-handler.js";
import {LocalTaskRunApprovalPushNotifier} from "../../features/notifications/infrastructure/local/local-task-run-approval-push-notifier.js";
import {LocalTeamNotificationSender} from "../../features/notifications/infrastructure/local/local-team-notification-sender.js";
import {
  HttpRuntimePushRelayClient,
  type RuntimePushRelayClient,
  UnavailableRuntimePushRelayClient,
} from "../../features/notifications/infrastructure/local/runtime-push-relay-client.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";
import {runDueTaskTriggers} from "../../features/scheduling/domain/usecases/run-due-task-triggers.js";
import {LocalTaskTriggerHttpHandler} from "../../features/scheduling/infrastructure/local/local-task-trigger-http-handler.js";
import {PollingTaskTriggerWorker} from "../../features/scheduling/infrastructure/local/polling-task-trigger-worker.js";
import {SQLiteTaskTriggerStore} from "../../features/scheduling/infrastructure/local/sqlite-task-trigger-store.js";
import {type TaskWorkflow} from "../../features/task_execution/domain/usecases/task-workflow.js";
import {createGenkitTaskWorkflow} from "../../features/task_execution/infrastructure/genkit/task-workflow.js";
import {LocalTaskActivityHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-activity-http-handler.js";
import {createLocalTaskBuilderAssistant} from "../../features/task_execution/infrastructure/local/local-task-builder-assistant.js";
import {LocalTaskDefinitionHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-definition-http-handler.js";
import {LocalTaskMessageSender} from "../../features/task_execution/infrastructure/local/local-task-message-sender.js";
import {LocalTaskRunHttpHandler} from "../../features/task_execution/infrastructure/local/local-task-run-http-handler.js";
import {SQLiteActivityStore} from "../../features/task_execution/infrastructure/local/sqlite-activity-store.js";
import {SQLiteTaskDefinitionStore} from "../../features/task_execution/infrastructure/local/sqlite-task-definition-store.js";
import {SQLiteTaskRunDispatcher} from "../../features/task_execution/infrastructure/local/sqlite-task-run-dispatcher.js";
import {SQLiteTaskRunJobStore} from "../../features/task_execution/infrastructure/local/sqlite-task-run-job-store.js";
import {SQLiteTaskRunStore} from "../../features/task_execution/infrastructure/local/sqlite-task-run-store.js";
import {SQLiteTaskStore} from "../../features/task_execution/infrastructure/local/sqlite-task-store.js";
import {TaskRunQueueWorker} from "../../features/task_execution/infrastructure/local/task-run-queue-worker.js";
import {SQLiteTeamContextStore} from "../../features/teams/infrastructure/local/sqlite-team-context-store.js";
import {type LocalWorkspaceTransferHttpHandler} from "../../features/workspace_transfer/infrastructure/local/local-workspace-transfer-http-handler.js";
import {createLocalWorkspaceTransferHttpHandler} from "../../features/workspace_transfer/infrastructure/local/workspace-transfer-composition.js";
import {LocalApplicationLogHttpHandler} from "../logging/local-application-log-http-handler.js";
import {LocalApplicationLogger} from "../logging/local-application-logger.js";
import {SQLiteLocalApplicationLogStore} from "../logging/sqlite-local-application-log-store.js";
import {LocalAssistantHttpHandler} from "./local-assistant-http-handler.js";
import {LocalRuntimeAccessCredentialStore} from "./local-runtime-access-credential-store.js";
import {LocalRuntimeLoginHttpHandler} from "./local-runtime-login-http-handler.js";
import {LocalRuntimeRealtimeNotifier} from "./local-runtime-realtime-notifier.js";
import {LocalRuntimeRealtimeTicketHttpHandler} from "./local-runtime-realtime-ticket-http-handler.js";
import {LocalRuntimeRealtimeTicketStore} from "./local-runtime-realtime-ticket-store.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";
import {type LocalRuntimeSetupCode} from "./local-runtime-setup-code.js";
import {LocalRuntimeSetupHttpHandler} from "./local-runtime-setup-http-handler.js";
import {type LocalRuntimeWorkspace} from "./local-runtime-workspace.js";

export type LocalRuntimeComposition = {
  controllers: LocalRuntimeControllers;
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
  database: RuntimeDatabase;
  runtimeRoot: string;
  workspace: LocalRuntimeWorkspace;
  fieldCipher: SensitiveFieldCipher;
  /** Prozessweit, im Entrypoint erzeugt — beide Setup-Wege teilen ihn. */
  setupCode: LocalRuntimeSetupCode;
  sessions: Pick<LocalRuntimeSessionStore, "createSession">;
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
    options.fieldCipher,
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
  const credentialStore = new LocalRuntimeAccessCredentialStore(options.database);
  const languageModelResolver = new CatalogGenkitLanguageModelResolver(
    new SQLiteLanguageModelCatalog(options.database, languageModelSecretStore),
  );
  const languageModelDefaultsStore = new SQLiteLanguageModelDefaultsStore(options.database);
  const controllers = {
    setup: new LocalRuntimeSetupHttpHandler({
      credentials: credentialStore,
      setupCode: options.setupCode,
    }),
    login: new LocalRuntimeLoginHttpHandler(credentialStore, options.sessions),
    realtimeTickets: new LocalRuntimeRealtimeTicketHttpHandler(realtimeTicketStore),
    taskRuns: new LocalTaskRunHttpHandler(taskWorkflow, options.workspace.userId, applicationLogger, realtimeNotifier),
    pushDevices: new LocalPushDeviceHttpHandler(options.signedLicense, pushRelay),
    mailRelay: new LocalMailRelayHttpHandler(options.signedLicense, mailRelay),
    tasks: new LocalTaskDefinitionHttpHandler(
      taskDefinitionStore,
      options.workspace.teamId,
      options.workspace.userId,
      realtimeNotifier,
    ),
    languageModels: new LocalLanguageModelHttpHandler(languageModelStore, options.workspace.teamId, realtimeNotifier),
    languageModelDefaults: new LocalLanguageModelDefaultsHttpHandler(
      languageModelDefaultsStore,
      options.workspace.teamId,
      realtimeNotifier,
    ),
    data: new LocalDataHttpHandler(documentStore, options.workspace.teamId),
    modelCatalog: new LocalModelCatalogHttpHandler(
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
    activities: new LocalTaskActivityHttpHandler(options.database, options.workspace.teamId),
    logs: new LocalApplicationLogHttpHandler(applicationLogStore, options.workspace.teamId, realtimeNotifier),
    knowledge: new LocalKnowledgeNoteHttpHandler(options.database, options.workspace.teamId, realtimeNotifier),
    triggers: new LocalTaskTriggerHttpHandler(options.database, options.workspace.teamId, options.workspace.userId, realtimeNotifier),
    files: new LocalFileResourceHttpHandler(
      options.database, teamFileStore, options.workspace.teamId, options.workspace.userId, realtimeNotifier,
    ),
    assistants: new LocalAssistantHttpHandler(
      () => createLocalTaskBuilderAssistant(
        options.workspace.teamId, languageModelResolver, languageModelDefaultsStore,
      ),
      () => createLocalKnowledgeBaseAssistant(
        options.database, options.workspace.teamId, languageModelResolver, languageModelDefaultsStore,
      ),
      options.workspace.userId,
    ),
    transfer: createLocalWorkspaceTransferHttpHandler({
      database: options.database,
      runtimeRoot: options.runtimeRoot,
      teamId: options.workspace.teamId,
      notifier: realtimeNotifier,
      logger: applicationLogger,
    }),
  };
  return {
    controllers,
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
      languageModelDefaultsStore: new SQLiteLanguageModelDefaultsStore(options.database),
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

export type LocalRuntimeControllers = {
  setup: LocalRuntimeSetupHttpHandler;
  login: LocalRuntimeLoginHttpHandler;
  realtimeTickets: LocalRuntimeRealtimeTicketHttpHandler;
  taskRuns: LocalTaskRunHttpHandler;
  pushDevices: LocalPushDeviceHttpHandler;
  mailRelay: LocalMailRelayHttpHandler;
  tasks: LocalTaskDefinitionHttpHandler;
  languageModels: LocalLanguageModelHttpHandler;
  languageModelDefaults: LocalLanguageModelDefaultsHttpHandler;
  data: LocalDataHttpHandler;
  modelCatalog: LocalModelCatalogHttpHandler;
  activities: LocalTaskActivityHttpHandler;
  logs: LocalApplicationLogHttpHandler;
  knowledge: LocalKnowledgeNoteHttpHandler;
  triggers: LocalTaskTriggerHttpHandler;
  files: LocalFileResourceHttpHandler;
  assistants: LocalAssistantHttpHandler;
  transfer: LocalWorkspaceTransferHttpHandler;
};
