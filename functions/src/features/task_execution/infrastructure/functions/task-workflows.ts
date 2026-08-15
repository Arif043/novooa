import {genkit} from "genkit/beta";
import {isSignedIn, onCallGenkit} from "firebase-functions/v2/https";
import {onTaskDispatched} from "firebase-functions/v2/tasks";
import {
  reviewTaskRunInputSchema,
  reviewTaskRunOutputSchema,
  runTaskDefinitionInputSchema,
  runTaskDefinitionOutputSchema,
} from "../genkit/runner/task-definition.js";
import {
  loadTaskDefinition,
} from "../genkit/runner/task-definition-loader.js";
import {aiProviderPlugins} from "../genkit/runner/ai-models.js";
import {geminiApiKey} from "../../../../shared/genkit/gemini-secret.js";
import {logException, withExceptionLogging} from "../../../../shared/logging/logger.js";
import {twilioAccountSid, twilioAuthToken} from "../../../communication/infrastructure/twilio/twilio-secrets.js";
import {
  mailConnectorEncryptionKey,
  microsoftGraphClientSecret,
} from "../../../communication/infrastructure/microsoft_graph/microsoft-graph-config.js";
import {FirebaseObjectStore} from "../../../files/infrastructure/firebase/firebase-object-store.js";
import {FirestoreTeamFileStore} from "../../../files/infrastructure/firebase/firestore-team-file-store.js";
import {FirebaseTaskMessageSender} from "../../../communication/infrastructure/firebase/firebase-task-message-sender.js";
import {FirestoreKnowledgeBaseStore} from
  "../../../knowledge_base/infrastructure/firebase/firestore-knowledge-base-store.js";
import {FirestoreTeamContextStore} from
  "../../../teams/infrastructure/firebase/firestore-team-context-store.js";
import {FirestoreTaskStore} from "../firebase/firestore-task-store.js";
import {
  createFirebaseTaskRunStore,
} from "../firebase/firebase-task-run-store-factory.js";
import {
  createFirebaseTaskRunApprovalNotificationStore,
} from "../../../notifications/infrastructure/firebase/firebase-task-run-approval-notification-store-factory.js";
import {
  FirebaseTaskRunDispatcher,
} from "../firebase/firebase-task-run-dispatcher.js";
import {
  handleTaskRunDispatch,
  taskRunDispatchPayloadSchema,
  type TaskRunDispatchPayload,
} from "../genkit/runner/task-run-task.js";

const workerSecrets = [
  twilioAccountSid,
  twilioAuthToken,
  microsoftGraphClientSecret,
  mailConnectorEncryptionKey,
  geminiApiKey,
];

const ai = genkit({
  plugins: aiProviderPlugins(),
});

const taskStore = new FirestoreTaskStore();
const taskRunStore = createFirebaseTaskRunStore(
  createFirebaseTaskRunApprovalNotificationStore(),
);
const objectStore = new FirebaseObjectStore();
const teamFileStore = new FirestoreTeamFileStore();
const messageSender = new FirebaseTaskMessageSender();
const knowledgeBaseStore = new FirestoreKnowledgeBaseStore();
const teamContextStore = new FirestoreTeamContextStore();
const workerStores = {
  taskStore,
  taskRunStore,
  objectStore,
  teamFileStore,
  messageSender,
  knowledgeBaseStore,
};
const taskRunDispatcher = new FirebaseTaskRunDispatcher();
const callableOptions = {
  authPolicy: isSignedIn(),
  invoker: "public" as const,
  secrets: [geminiApiKey],
};

export const taskDefinitionFlow = ai.defineFlow(
  {
    name: "runTaskDefinitionFlow",
    inputSchema: runTaskDefinitionInputSchema,
    outputSchema: runTaskDefinitionOutputSchema,
  },
  async (input, runtime) => {
    let title = "";
    try {
      const taskDefinition = await loadTaskDefinition(
        input.taskId,
        runtime.context,
        {taskStore, teamContextStore},
      );
      title = taskDefinition.title;
      const teamId = await teamIdFromContext(runtime.context);
      const run = await taskRunStore.enqueueTaskRun({
        teamId,
        task: taskDefinition,
        context: input.context,
      });
      await taskRunDispatcher.dispatchTaskRun({
        teamId,
        runId: run.runId,
        mode: "start",
      });
      return {runId: run.runId, taskId: run.taskId, status: "queued" as const};
    } catch (error) {
      logException("run_task_definition_flow.failed", error, {
        taskId: input.taskId,
        title,
      });
      throw error;
    }
  },
);

export const runTaskDefinitionFlow = onCallGenkit(
  callableOptions,
  taskDefinitionFlow,
);

export const reviewTaskRunFlow = ai.defineFlow(
  {
    name: "reviewTaskRunFlow",
    inputSchema: reviewTaskRunInputSchema,
    outputSchema: reviewTaskRunOutputSchema,
  },
  async (input, runtime) => withExceptionLogging(
    "review_task_run.failed",
    async () => {
    const teamId = await teamIdFromContext(runtime.context);
    const reviewableRun = await taskRunStore.loadReviewableRun(
      teamId,
      input.runId,
    );
    if (input.decision === "reject") {
      await taskRunStore.rejectTaskRun(teamId, reviewableRun.run.runId);
      return {runId: input.runId, status: "rejected" as const};
    }
    await taskRunStore.approveTaskRun(
      teamId,
      reviewableRun.run.runId,
      input.output,
    );
    await taskRunDispatcher.dispatchTaskRun({
      teamId,
      runId: reviewableRun.run.runId,
      mode: "resume",
    });
    return {runId: input.runId, status: "queued" as const};
    },
    {runId: input.runId},
  ),
);

export const reviewTaskRun = onCallGenkit(callableOptions, reviewTaskRunFlow);

export const runTaskRunTask = onTaskDispatched<TaskRunDispatchPayload>(
  {
    region: "europe-west3",
    secrets: workerSecrets,
    retryConfig: {
      maxAttempts: 3,
      minBackoffSeconds: 30,
      maxBackoffSeconds: 300,
    },
    rateLimits: {
      maxConcurrentDispatches: 10,
      maxDispatchesPerSecond: 5,
    },
  },
  async (request) => withExceptionLogging(
    "task_run_task.handler_failed",
    async () => {
    const payload = taskRunDispatchPayloadSchema.parse(request.data);
    await handleTaskRunDispatch(ai, payload, workerStores);
    },
  ),
);

async function teamIdFromContext(context: unknown): Promise<string> {
  const auth = (context as {auth?: {uid?: string}} | undefined)?.auth;
  if (!auth?.uid) throw new Error("Auth context is missing.");
  return teamContextStore.currentTeamIdForUid(auth.uid);
}
