import {type LocalMlService} from "../../features/machine_learning/infrastructure/local/local-ml-service.js";
import {createLocalModelCache} from "../../features/machine_learning/infrastructure/local/local-model-cache.js";
import {type FileEventPublisher, noFileEventPublisher} from "../../features/files/domain/repositories/file-event-publisher.js";
import {SQLiteFolderAncestry} from "../../features/files/infrastructure/local/sqlite-folder-ancestry.js";
import {TokenBucketRateLimiter} from "../rate_limiting/domain/usecases/token-bucket-rate-limiter.js";
import {ReceiveWebhook} from "../../features/webhooks/domain/usecases/receive-webhook.js";
import {InMemoryBucketStateStore} from "../rate_limiting/infrastructure/local/in-memory-bucket-state-store.js";
import {DispatchFileEvent} from "../../features/scheduling/domain/usecases/dispatch-file-event.js";
import {type RuntimeDatabase} from "../../db/database.js";
import {LocalMailRelayEventProcessor} from "../../features/communication/infrastructure/local/local-mail-relay-event-processor.js";
import {RuntimeMailRelayWorker} from "../../features/communication/infrastructure/local/polling-runtime-mail-relay-worker.js";
import {type RuntimeMailRelayClient} from "../../features/communication/infrastructure/local/runtime-mail-relay-client.js";
import {SQLiteInboundChannelMessageStore} from "../../features/communication/infrastructure/local/sqlite-inbound-channel-message-store.js";
import {SQLiteDocumentStore} from "../../features/data/infrastructure/local/sqlite-document-store.js";
import {SQLiteFileSettingsStore} from "../../features/files/infrastructure/local/sqlite-file-settings-store.js";
import {SQLiteTeamFileStore} from "../../features/files/infrastructure/local/sqlite-team-file-store.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "../../features/language_models/infrastructure/local/encrypted-sqlite-language-model-secret-store.js";
import {SQLiteLanguageModelCatalog} from "../../features/language_models/infrastructure/local/sqlite-language-model-catalog.js";
import {type RuntimeLicenseActivation} from "../../features/licensing/domain/entities/runtime-license-activation.js";
import {type SignedRuntimeLicense} from "../../features/licensing/domain/entities/runtime-license-lease.js";
import {
  RuntimeFirebaseSession,
  runtimeFirebaseConfigurationFromEnvironment,
} from "../../features/licensing/infrastructure/local/runtime-firebase-session.js";
import {FirebaseRuntimeModelCatalog} from "../../features/machine_learning/infrastructure/local/firebase-runtime-model-catalog.js";
import {LocalTaskRunApprovalPushNotifier} from "../../features/notifications/infrastructure/local/local-task-run-approval-push-notifier.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";
import {runDueTaskTriggers} from "../../features/scheduling/domain/usecases/run-due-task-triggers.js";
import {PollingTaskTriggerWorker} from "../../features/scheduling/infrastructure/local/polling-task-trigger-worker.js";
import {SQLiteTaskTriggerStore} from "../../features/scheduling/infrastructure/local/sqlite-task-trigger-store.js";
import {type TaskWorkflow} from "../../features/task_execution/domain/usecases/task-workflow.js";
import {SQLiteActivityStore} from "../../features/task_execution/infrastructure/local/sqlite-activity-store.js";
import {SQLiteTaskRunDispatcher} from "../../features/task_execution/infrastructure/local/sqlite-task-run-dispatcher.js";
import {SQLiteTaskRunJobStore} from "../../features/task_execution/infrastructure/local/sqlite-task-run-job-store.js";
import {SQLiteTaskRunStore} from "../../features/task_execution/infrastructure/local/sqlite-task-run-store.js";
import {SQLiteTaskStore} from "../../features/task_execution/infrastructure/local/sqlite-task-store.js";
import {TaskRunQueueWorker} from "../../features/task_execution/infrastructure/local/task-run-queue-worker.js";
import {failAbandonedTaskRun} from "../../features/task_execution/infrastructure/local/fail-abandoned-task-run.js";
import {LocalApplicationLogger} from "../logging/local-application-logger.js";
import {SQLiteLocalApplicationLogStore} from "../logging/sqlite-local-application-log-store.js";
import {type LocalRuntimeRealtimeNotifier} from "./local-runtime-realtime-notifier.js";
import {mailRelayFromEnvironment, pushRelayFromEnvironment} from "./local-runtime-relays.js";
import {ConnectionHttpClient} from "../../features/connections/infrastructure/local/connection-http-client.js";
import {OAuthTokenProvider} from "../../features/connections/infrastructure/local/oauth-token-provider.js";
import {SQLiteConnectionStore} from "../../features/connections/infrastructure/local/sqlite-connection-store.js";
import {StoredConnectionAuthorizer} from "../../features/connections/infrastructure/local/stored-connection-authorizer.js";
import {integrationWebhookInterpreters, registerIntegrationPlugins} from "../../features/integrations/index.js";
import {createDefaultNodeExecutorRegistry} from "../../features/task_execution/infrastructure/genkit/runner/node-executor-registry.js";
import {createLocalTaskWorkflow} from "./local-runtime-task-workflow.js";
import {type LocalRuntimeWorkspace} from "./local-runtime-workspace.js";
import {type LocalRuntimeWorkspaceContext} from "./local-runtime-workspace-context.js";

export type LocalRuntimeComposition = {
  workspaceContext: LocalRuntimeWorkspaceContext;
  taskRunWorker: TaskRunQueueWorker;
  taskTriggerWorker: PollingTaskTriggerWorker;
  mailRelayWorker: RuntimeMailRelayWorker | undefined;
  firebaseSession: RuntimeFirebaseSession | undefined;
  applicationLogger: LocalApplicationLogger;
};

export type LocalRuntimeCompositionOptions = {
  database: RuntimeDatabase;
  runtimeRoot: string;
  workspace: LocalRuntimeWorkspace;
  fieldCipher: SensitiveFieldCipher;
  /** Prozessweit, im Entrypoint erzeugt — beide Setup-Wege teilen ihn. */
  /** App-weit: Realtime-Abonnenten überdauern einen Arbeitsbereichswechsel. */
  realtimeNotifier: LocalRuntimeRealtimeNotifier;
  isLicenseActive?: () => boolean;
  signedLicense: () => SignedRuntimeLicense | null;
  activeLicenseActivation: () => RuntimeLicenseActivation | null;
  /** Prozessweit: Die Anmeldung beim ML-Dienst überdauert einen Arbeitsbereichswechsel. */
  mlService: LocalMlService | undefined;
};

export function createLocalRuntimeComposition(
  options: LocalRuntimeCompositionOptions,
): LocalRuntimeComposition {
  const realtimeNotifier = options.realtimeNotifier;
  const activityStore = new SQLiteActivityStore(options.database);
  const applicationLogStore = new SQLiteLocalApplicationLogStore(options.database);
  const applicationLogger = new LocalApplicationLogger(
    applicationLogStore,
    options.workspace.teamId,
  );
  const pushRelay = pushRelayFromEnvironment();
  const mailRelay = mailRelayFromEnvironment();
  const firebaseSession = firebaseSessionFor();
  const taskRunStore = new SQLiteTaskRunStore(
    options.database,
    activityStore,
    new LocalTaskRunApprovalPushNotifier(options.signedLicense, pushRelay, applicationLogger),
  );
  let fileEventDispatcher: FileEventPublisher = noFileEventPublisher;
  const fileEvents: FileEventPublisher = {publish: (event) => fileEventDispatcher.publish(event)};
  const teamFileStore = new SQLiteTeamFileStore(
    options.database, options.runtimeRoot, new SQLiteFileSettingsStore(options.database), fileEvents,
  );
  const jobStore = new SQLiteTaskRunJobStore(options.database);
  const taskStore = new SQLiteTaskStore(options.database);
  const languageModelSecretStore = new EncryptedSQLiteLanguageModelSecretStore(
    options.database,
    options.fieldCipher,
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
      onAbandoned: (job) => failAbandonedTaskRun(taskRunStore, job),
      onDrainFailure: (error) => applicationLogger.exception(
        "task_run_worker.drain_failed", error, {teamId: options.workspace.teamId},
      ),
      notifier: realtimeNotifier,
    },
  );
  const taskRunDispatcher = new SQLiteTaskRunDispatcher(jobStore, taskRunWorker);
  fileEventDispatcher = new DispatchFileEvent({
    triggerStore: new SQLiteTaskTriggerStore(options.database), taskStore, taskRunStore, taskRunDispatcher,
    folders: new SQLiteFolderAncestry(options.database),
    onFailure: (error, trigger) => applicationLogger.exception(
      "file_event_trigger.failed", error, {teamId: options.workspace.teamId, triggerId: trigger?.id},
    ),
    onLoopPrevented: (trigger, event) => {
      applicationLogger.info("file_event_trigger.loop_prevented", {
        teamId: options.workspace.teamId, triggerId: trigger.id, fileId: event.fileId, triggerChain: event.triggerChain,
      });
      applicationLogger.readableError(
        `Schleife verhindert: Ein Auslöser wurde nicht gestartet, weil die Datei „${event.displayName}“ `
        + "von einer Aufgabe stammt, die durch denselben Auslöser gestartet wurde.",
      );
    },
  });
  const outboundHttpClient = new ConnectionHttpClient(new StoredConnectionAuthorizer(
    new SQLiteConnectionStore(options.database, languageModelSecretStore), new OAuthTokenProvider(),
  ));
  const systemModelCatalog = firebaseSession === undefined ? undefined : new FirebaseRuntimeModelCatalog(firebaseSession);
  const modelCache = systemModelCatalog === undefined ? undefined : createLocalModelCache({
    database: options.database, runtimeRoot: options.runtimeRoot, teamId: options.workspace.teamId,
    systemModelCatalog, notifier: realtimeNotifier, logger: applicationLogger, mlService: options.mlService?.client,
  });
  taskWorkflow = createLocalTaskWorkflow({
    database: options.database, runtimeRoot: options.runtimeRoot, signedLicense: options.signedLicense,
    taskRunStore, teamFileStore, taskRunDispatcher, logger: applicationLogger,
    languageModelCatalog: new SQLiteLanguageModelCatalog(options.database, languageModelSecretStore),
    documentStore, mailRelay, pushRelay,
    executorRegistry: registerIntegrationPlugins(createDefaultNodeExecutorRegistry()),
    outboundHttpClient,
    modelCache,
    mlService: options.mlService?.client,
  });
  const webhookBuckets = new InMemoryBucketStateStore();
  const webhooks = new ReceiveWebhook({
    teamId: options.workspace.teamId,
    triggerStore: new SQLiteTaskTriggerStore(options.database), taskStore, taskRunStore, taskRunDispatcher,
    secrets: languageModelSecretStore,
    interpreters: integrationWebhookInterpreters(outboundHttpClient),
    // Fehlversuche: kleiner Eimer. Gültige Aufrufe je Auslöser: im Schnitt 5 pro Sekunde, Stöße bis 20.
    failures: new TokenBucketRateLimiter(webhookBuckets, {current: async () => ({capacity: 30, refillPerSecond: 1})}),
    triggers: new TokenBucketRateLimiter(webhookBuckets, {current: async () => ({capacity: 20, refillPerSecond: 5})}),
  });
  const mailRelayWorker = mailRelayWorkerFor(
    options, mailRelay, taskStore, taskRunStore, taskRunDispatcher, applicationLogger,
  );
  applicationLogger.info("local_runtime.workspace_activated", {
    teamId: options.workspace.teamId,
  });
  const workspaceContext: LocalRuntimeWorkspaceContext = {
    teamId: options.workspace.teamId,
    ownerUid: options.workspace.userId,
    logger: applicationLogger,
    taskWorkflow,
    fileEvents,
    webhooks,
    systemModelCatalog,
    modelCache,
  };
  return {
    workspaceContext,
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
  };
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
