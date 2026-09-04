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
import {createCloudTaskRuntime} from "../firebase/cloud-task-runtime-factory.js";
import {
  handleTaskRunDispatch,
  taskRunDispatchPayloadSchema,
  type TaskRunDispatchPayload,
} from "../genkit/runner/task-run-task.js";
import {responseOutputsForTaskRun} from
  "../../domain/usecases/task-run-response-outputs.js";

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

const taskRuntime = createCloudTaskRuntime();
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
        {taskStore: taskRuntime.taskStore, teamContextStore: taskRuntime.teamContextStore},
      );
      title = taskDefinition.title;
      const teamId = await teamIdFromContext(runtime.context);
      const run = await taskRuntime.taskRunStore.enqueueTaskRun({
        teamId,
        task: taskDefinition,
        context: input.context,
      });
      await taskRuntime.taskRunDispatcher.dispatchTaskRun({
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
    const reviewableRun = await taskRuntime.taskRunStore.loadReviewableRun(
      teamId,
      input.runId,
    );
    if (input.decision === "reject") {
      await taskRuntime.taskRunStore.rejectTaskRun(teamId, reviewableRun.run.runId);
      return {runId: input.runId, status: "rejected" as const};
    }
    const responseOutputs = await responseOutputsForTaskRun(
      reviewableRun.resumeState,
      input.output,
      input.formValues,
      teamId,
      taskRuntime.teamFileStore,
    );
    await taskRuntime.taskRunStore.approveTaskRun(
      teamId,
      reviewableRun.run.runId,
      responseOutputs,
    );
    await taskRuntime.taskRunDispatcher.dispatchTaskRun({
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
    await handleTaskRunDispatch(ai, payload, taskRuntime.workerStores);
    },
  ),
);

async function teamIdFromContext(context: unknown): Promise<string> {
  const auth = (context as {auth?: {uid?: string}} | undefined)?.auth;
  if (!auth?.uid) throw new Error("Auth context is missing.");
  return taskRuntime.teamContextStore.currentTeamIdForUid(auth.uid);
}
