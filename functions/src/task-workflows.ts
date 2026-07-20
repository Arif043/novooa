import {genkit} from "genkit/beta";
import {isSignedIn, onCallGenkit} from "firebase-functions/v2/https";
import {onTaskDispatched} from "firebase-functions/v2/tasks";
import {
  reviewTaskRunInputSchema,
  reviewTaskRunOutputSchema,
  runTaskDefinitionInputSchema,
  runTaskDefinitionOutputSchema,
} from "./task-runner/task-definition.js";
import {
  loadTaskDefinition,
} from "./task-runner/task-definition-loader.js";
import {aiProviderPlugins} from "./task-runner/ai-models.js";
import {errorDetails, logError} from "./task-runner/structured-logger.js";
import {twilioAccountSid, twilioAuthToken} from "./channels/twilio-secrets.js";
import {sendgridApiKey} from "./channels/sendgrid-secrets.js";
import {FirebaseObjectStore} from "./infrastructure/firebase/firebase-object-store.js";
import {FirestoreKnowledgeBaseStore} from
  "./infrastructure/firebase/firestore-knowledge-base-store.js";
import {FirestoreTeamContextStore} from
  "./infrastructure/firebase/firestore-team-context-store.js";
import {FirestoreTaskStore} from "./infrastructure/firebase/firestore-task-store.js";
import {FirestoreTaskRunStore} from "./infrastructure/firebase/firestore-task-run-store.js";
import {
  FirebaseTaskRunDispatcher,
} from "./infrastructure/firebase/firebase-task-run-dispatcher.js";
import {
  handleTaskRunDispatch,
  taskRunDispatchPayloadSchema,
  type TaskRunDispatchPayload,
} from "./task-runner/task-run-task.js";

const communicationSecrets = [twilioAccountSid, twilioAuthToken, sendgridApiKey];

const ai = genkit({
  plugins: aiProviderPlugins(),
});

const taskStore = new FirestoreTaskStore();
const taskRunStore = new FirestoreTaskRunStore();
const objectStore = new FirebaseObjectStore();
const knowledgeBaseStore = new FirestoreKnowledgeBaseStore();
const teamContextStore = new FirestoreTeamContextStore();
const workerStores = {taskStore, taskRunStore, objectStore, knowledgeBaseStore};
const taskRunDispatcher = new FirebaseTaskRunDispatcher();
const callableOptions = {
  authPolicy: isSignedIn(),
  invoker: "public" as const,
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
      logError("run_task_definition_flow.failed", {
        taskId: input.taskId,
        title,
        error: errorDetails(error),
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
  async (input, runtime) => {
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
);

export const reviewTaskRun = onCallGenkit(callableOptions, reviewTaskRunFlow);

export const runTaskRunTask = onTaskDispatched<TaskRunDispatchPayload>(
  {
    region: "europe-west3",
    secrets: communicationSecrets,
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
  async (request) => {
    const payload = taskRunDispatchPayloadSchema.parse(request.data);
    await handleTaskRunDispatch(ai, payload, workerStores);
  },
);

async function teamIdFromContext(context: unknown): Promise<string> {
  const auth = (context as {auth?: {uid?: string}} | undefined)?.auth;
  if (!auth?.uid) throw new Error("Auth context is missing.");
  return teamContextStore.currentTeamIdForUid(auth.uid);
}
