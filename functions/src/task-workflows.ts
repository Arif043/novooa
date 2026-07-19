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
} from "./task-runner/task-activity-logger.js";
import {aiProviderPlugins} from "./task-runner/ai-models.js";
import {errorDetails, logError} from "./task-runner/structured-logger.js";
import {currentTeamIdForUid} from "./team-context.js";
import {twilioAccountSid, twilioAuthToken} from "./channels/twilio-secrets.js";
import {sendgridApiKey} from "./channels/sendgrid-secrets.js";
import {FirestoreTaskStore} from "./task-runner/stores/firestore-task-store.js";
import {FirestoreTaskRunStore} from "./task-runner/stores/firestore-task-run-store.js";
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
const workerStores = {taskStore, taskRunStore};

export const taskDefinitionFlow = ai.defineFlow(
  {
    name: "runTaskDefinitionFlow",
    inputSchema: runTaskDefinitionInputSchema,
    outputSchema: runTaskDefinitionOutputSchema,
  },
  async (input, runtime) => {
    let title = "";
    try {
      const taskDefinition = await loadTaskDefinition(input.taskId, runtime.context);
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

export const runTaskDefinitionFlow = onCallGenkit({authPolicy: isSignedIn()}, taskDefinitionFlow);

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

export const reviewTaskRun = onCallGenkit({authPolicy: isSignedIn()}, reviewTaskRunFlow);

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
  return currentTeamIdForUid(auth.uid);
}
