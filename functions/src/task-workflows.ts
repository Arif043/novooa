import {genkit} from "genkit/beta";
import {isSignedIn, onCallGenkit} from "firebase-functions/v2/https";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {
  reviewTaskRunInputSchema,
  reviewTaskRunOutputSchema,
  runTaskDefinitionInputSchema,
  runTaskDefinitionOutputSchema,
  taskResumeStateSchema,
} from "./task-runner/task-definition.js";
import {
  loadTaskDefinition,
} from "./task-runner/task-definition-loader.js";
import {
  runFromDocument,
} from "./domain/repositories/task-run-store.js";
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
  continueApprovedTaskRun,
  executeQueuedTaskRun,
} from "./task-runner/task-run-worker.js";

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
    return {runId: input.runId, status: "queued" as const};
  },
);

export const reviewTaskRun = onCallGenkit(callableOptions, reviewTaskRunFlow);

export const runTaskDefinitionWorker = onDocumentCreated(
  {
    document: "teams/{teamId}/taskRuns/{runId}",
    secrets: communicationSecrets,
  },
  async (event) => {
    const teamId = event.params.teamId;
    const run = runFromDocument(event.data?.data() ?? {});
    try {
      await executeQueuedTaskRun(ai, {teamId, run, stores: workerStores});
    } catch (error) {
      logError("run_task_definition_worker.failed", {
        taskId: run.taskId,
        runId: run.runId,
        error: errorDetails(error),
      });
      await taskRunStore.markRunFailed(teamId, run, error);
    }
  },
);

export const resumeApprovedTaskRunWorker = onDocumentUpdated(
  {
    document: "teams/{teamId}/taskRuns/{runId}",
    secrets: communicationSecrets,
  },
  async (event) => {
    const before = event.data?.before.data() ?? {};
    const after = event.data?.after.data() ?? {};
    if (!shouldResumeApprovedRun(before.status, after.status)) return;
    const run = runFromDocument(after);
    const resumeState = taskResumeStateSchema.parse(after.resumeState);
    const approvedOutput = String(after.approvedOutput ?? "");
    try {
      await continueApprovedTaskRun(ai, {
        teamId: event.params.teamId,
        run,
        resumeState,
        approvedOutput,
        stores: workerStores,
      });
    } catch (error) {
      await taskRunStore.markRunFailed(event.params.teamId, run, error);
      throw error;
    }
  },
);

function shouldResumeApprovedRun(beforeStatus: unknown, afterStatus: unknown) {
  return beforeStatus === "waitingForApproval" && afterStatus === "queued";
}

async function teamIdFromContext(context: unknown): Promise<string> {
  const auth = (context as {auth?: {uid?: string}} | undefined)?.auth;
  if (!auth?.uid) throw new Error("Auth context is missing.");
  return teamContextStore.currentTeamIdForUid(auth.uid);
}
