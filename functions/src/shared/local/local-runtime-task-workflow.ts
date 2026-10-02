import {createDirectorySkillStore} from "../../features/skills/infrastructure/local/skills-composition.js";
import {LanguageModelTranscription} from "../../features/speech_transcription/domain/usecases/language-model-transcription.js";
import {defaultTranscriptionProviders} from "../../features/speech_transcription/infrastructure/default-transcription-providers.js";
import {LanguageModelSpeech} from "../../features/speech_synthesis/domain/usecases/language-model-speech.js";
import {defaultSpeechProviders} from "../../features/speech_synthesis/infrastructure/default-speech-providers.js";
import {type RuntimeDatabase} from "../../db/database.js";
import {type RuntimeMailRelayClient} from "../../features/communication/infrastructure/local/runtime-mail-relay-client.js";
import {type DocumentStore} from "../../features/data/domain/repositories/document-store.js";
import {LocalObjectStore} from "../../features/files/infrastructure/local/local-object-store.js";
import {type LocalTeamFileStore} from "../../features/files/infrastructure/local/local-team-file-store.js";
import {SQLiteKnowledgeBaseStore} from "../../features/knowledge_base/infrastructure/local/sqlite-knowledge-base-store.js";
import {CatalogGenkitLanguageModelResolver} from "../../features/language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type SQLiteLanguageModelCatalog} from "../../features/language_models/infrastructure/local/sqlite-language-model-catalog.js";
import {SQLiteLanguageModelDefaultsStore} from "../../features/language_models/infrastructure/local/sqlite-language-model-defaults-store.js";
import {type SignedRuntimeLicense} from "../../features/licensing/domain/entities/runtime-license-lease.js";
import {createLocalSidecarModelInference} from "../../features/machine_learning/infrastructure/local/local-sidecar-model-inference.js";
import {UnavailableLocalModelInference} from "../../features/machine_learning/infrastructure/local/unavailable-local-model-inference.js";
import {LocalTeamNotificationSender} from "../../features/notifications/infrastructure/local/local-team-notification-sender.js";
import {type RuntimePushRelayClient} from "../../features/notifications/infrastructure/local/runtime-push-relay-client.js";
import {createGenkitTaskWorkflow} from "../../features/task_execution/infrastructure/genkit/task-workflow.js";
import {LocalTaskMessageSender} from "../../features/task_execution/infrastructure/local/local-task-message-sender.js";
import {type SQLiteTaskRunDispatcher} from "../../features/task_execution/infrastructure/local/sqlite-task-run-dispatcher.js";
import {type SQLiteTaskRunStore} from "../../features/task_execution/infrastructure/local/sqlite-task-run-store.js";
import {SQLiteTaskStore} from "../../features/task_execution/infrastructure/local/sqlite-task-store.js";
import {SQLiteTeamContextStore} from "../../features/teams/infrastructure/local/sqlite-team-context-store.js";
import {type LocalApplicationLogger} from "../logging/local-application-logger.js";

export type LocalTaskWorkflowDependencies = {
  database: RuntimeDatabase;
  runtimeRoot: string;
  signedLicense: () => SignedRuntimeLicense | null;
  taskRunStore: SQLiteTaskRunStore;
  teamFileStore: LocalTeamFileStore;
  taskRunDispatcher: SQLiteTaskRunDispatcher;
  logger: LocalApplicationLogger;
  languageModelCatalog: SQLiteLanguageModelCatalog;
  documentStore: DocumentStore;
  mailRelay: RuntimeMailRelayClient;
  pushRelay: RuntimePushRelayClient;
};

/** Genkit-Task-Workflow der lokalen Runtime mit SQLite- und Dateisystem-Adaptern. */
export function createLocalTaskWorkflow(dependencies: LocalTaskWorkflowDependencies) {
  const {database, taskRunStore, teamFileStore, logger} = dependencies;
  return createGenkitTaskWorkflow({
    taskStore: new SQLiteTaskStore(database),
    taskRunStore,
    taskRunDispatcher: dependencies.taskRunDispatcher,
    teamContextStore: new SQLiteTeamContextStore(database),
    teamFileStore,
    logger,
    workerStores: {
      taskStore: new SQLiteTaskStore(database),
      taskRunStore,
      objectStore: new LocalObjectStore(dependencies.runtimeRoot),
      knowledgeBaseStore: new SQLiteKnowledgeBaseStore(database),
      teamFileStore,
      fileContentReader: teamFileStore,
      messageSender: new LocalTaskMessageSender(dependencies.signedLicense, dependencies.mailRelay),
      documentStore: dependencies.documentStore,
      modelInference: modelInferenceFor(database, dependencies.runtimeRoot),
      teamNotificationSender: new LocalTeamNotificationSender(dependencies.signedLicense, dependencies.pushRelay, logger),
      languageModelResolver: new CatalogGenkitLanguageModelResolver(dependencies.languageModelCatalog),
      skillContentReader: createDirectorySkillStore(dependencies.runtimeRoot),
      speechSynthesizer: new LanguageModelSpeech(dependencies.languageModelCatalog, defaultSpeechProviders()),
      speechTranscriber: new LanguageModelTranscription(dependencies.languageModelCatalog, defaultTranscriptionProviders()),
      languageModelDefaultsStore: new SQLiteLanguageModelDefaultsStore(database),
    },
  });
}

function modelInferenceFor(database: RuntimeDatabase, runtimeRoot: string) {
  const sidecarUrl = process.env.PYTHON_INFERENCE_SIDECAR_URL?.trim();
  return sidecarUrl
    ? createLocalSidecarModelInference(database, runtimeRoot, sidecarUrl)
    : new UnavailableLocalModelInference();
}
