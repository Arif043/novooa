import {FirebaseTaskMessageSender} from "../../../communication/infrastructure/firebase/firebase-task-message-sender.js";
import {FirebaseObjectStore} from "../../../files/infrastructure/firebase/firebase-object-store.js";
import {FirestoreTeamFileStore} from "../../../files/infrastructure/firebase/firestore-team-file-store.js";
import {FirestoreKnowledgeBaseStore} from "../../../knowledge_base/infrastructure/firebase/firestore-knowledge-base-store.js";
import {modelInference} from "../../../machine_learning/infrastructure/cloud_run/model-inference-service-config.js";
import {createFirebaseTaskRunApprovalNotificationStore} from "../../../notifications/infrastructure/firebase/firebase-task-run-approval-notification-store-factory.js";
import {FirebaseTeamNotificationSender} from "../../../notifications/infrastructure/firebase/firebase-team-notification-sender.js";
import {FirestoreTeamContextStore} from "../../../teams/infrastructure/firebase/firestore-team-context-store.js";
import {type TaskRunStore} from "../../domain/repositories/task-run-store.js";
import {FirebaseTaskRunDispatcher} from "./firebase-task-run-dispatcher.js";
import {createFirebaseTaskRunStore} from "./firebase-task-run-store-factory.js";
import {FirestoreTaskStore} from "./firestore-task-store.js";
import {type TaskRunWorkerStores} from "../genkit/runner/task-run-worker.js";
import {FirestoreLanguageModelCatalog} from "../../../language_models/infrastructure/firebase/firestore-language-model-catalog.js";
import {languageModelCipher} from "../../../language_models/infrastructure/firebase/language-model-encryption.js";
import {CatalogGenkitLanguageModelResolver} from "../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {FirestoreLanguageModelDefaultsStore} from "../../../language_models/infrastructure/firebase/firestore-language-model-defaults-store.js";
import {LanguageModelSpeech} from "../../../speech_synthesis/domain/usecases/language-model-speech.js";
import {defaultSpeechProviders} from "../../../speech_synthesis/infrastructure/default-speech-providers.js";
import {LanguageModelTranscription} from "../../../speech_transcription/domain/usecases/language-model-transcription.js";
import {defaultTranscriptionProviders} from "../../../speech_transcription/infrastructure/default-transcription-providers.js";
import {UnavailableDocumentStore} from "../../../data/infrastructure/unavailable-document-store.js";

export type CloudTaskRuntime = {
  taskStore: FirestoreTaskStore;
  taskRunStore: TaskRunStore;
  teamFileStore: FirestoreTeamFileStore;
  teamContextStore: FirestoreTeamContextStore;
  workerStores: TaskRunWorkerStores;
  taskRunDispatcher: FirebaseTaskRunDispatcher;
};

export function createCloudTaskRuntime(): CloudTaskRuntime {
  const taskStore = new FirestoreTaskStore();
  const taskRunStore = createFirebaseTaskRunStore(
    createFirebaseTaskRunApprovalNotificationStore(),
  );
  const teamFileStore = new FirestoreTeamFileStore();
  return {
    taskStore,
    taskRunStore,
    teamFileStore,
    teamContextStore: new FirestoreTeamContextStore(),
    workerStores: workerStoresFor(taskStore, taskRunStore, teamFileStore),
    taskRunDispatcher: new FirebaseTaskRunDispatcher(),
  };
}

function workerStoresFor(
  taskStore: FirestoreTaskStore,
  taskRunStore: TaskRunStore,
  teamFileStore: FirestoreTeamFileStore,
): TaskRunWorkerStores {
  const languageModelCatalog = new FirestoreLanguageModelCatalog(languageModelCipher);
  return {
    taskStore,
    taskRunStore,
    objectStore: new FirebaseObjectStore(),
    teamFileStore,
    fileContentReader: teamFileStore,
    messageSender: new FirebaseTaskMessageSender(),
    documentStore: new UnavailableDocumentStore(),
    knowledgeBaseStore: new FirestoreKnowledgeBaseStore(),
    modelInference: modelInference(),
    teamNotificationSender: new FirebaseTeamNotificationSender(),
    languageModelResolver: new CatalogGenkitLanguageModelResolver(languageModelCatalog),
    speechSynthesizer: new LanguageModelSpeech(languageModelCatalog, defaultSpeechProviders()),
    speechTranscriber: new LanguageModelTranscription(languageModelCatalog, defaultTranscriptionProviders()),
    languageModelDefaultsStore: new FirestoreLanguageModelDefaultsStore(),
  };
}
