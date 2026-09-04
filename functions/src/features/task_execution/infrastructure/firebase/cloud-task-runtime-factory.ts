import {FirebaseTaskMessageSender} from "../../../communication/infrastructure/firebase/firebase-task-message-sender.js";
import {FirebaseObjectStore} from "../../../files/infrastructure/firebase/firebase-object-store.js";
import {FirestoreTeamFileStore} from "../../../files/infrastructure/firebase/firestore-team-file-store.js";
import {FirestoreKnowledgeBaseStore} from "../../../knowledge_base/infrastructure/firebase/firestore-knowledge-base-store.js";
import {modelInference} from "../../../machine_learning/infrastructure/cloud_run/model-inference-service-config.js";
import {createFirebaseTaskRunApprovalNotificationStore} from "../../../notifications/infrastructure/firebase/firebase-task-run-approval-notification-store-factory.js";
import {FirestoreTeamContextStore} from "../../../teams/infrastructure/firebase/firestore-team-context-store.js";
import {type TaskRunStore} from "../../domain/repositories/task-run-store.js";
import {FirebaseTaskRunDispatcher} from "./firebase-task-run-dispatcher.js";
import {createFirebaseTaskRunStore} from "./firebase-task-run-store-factory.js";
import {FirestoreTaskStore} from "./firestore-task-store.js";
import {type TaskRunWorkerStores} from "../genkit/runner/task-run-worker.js";

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
  return {
    taskStore,
    taskRunStore,
    objectStore: new FirebaseObjectStore(),
    teamFileStore,
    fileContentReader: teamFileStore,
    messageSender: new FirebaseTaskMessageSender(),
    knowledgeBaseStore: new FirestoreKnowledgeBaseStore(),
    modelInference: modelInference(),
  };
}
