import {genkit} from "genkit";
import {openAICompatible} from "@genkit-ai/compat-oai";
import {isSignedIn, onCallGenkit} from "firebase-functions/v2/https";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {
  executeTaskGraph,
  resumeTaskGraph,
} from "./task-runner/task-graph-runner.js";
import {
  reviewTaskRunInputSchema,
  reviewTaskRunOutputSchema,
  runTaskDefinitionInputSchema,
  runTaskDefinitionOutputSchema,
  taskResumeStateSchema,
  type TaskResumeState,
} from "./task-runner/task-definition.js";
import {
  loadTaskDefinition,
  loadTaskDefinitionForTeam,
} from "./task-runner/task-definition-loader.js";
import {
  enqueueTaskRun,
  markRunFailed,
  markRunStarted,
  markRunSucceeded,
  markRunWaitingForApproval,
  runFromDocument,
} from "./task-runner/task-activity-logger.js";
import {
  approveTaskRun,
  loadReviewableRun,
  rejectTaskRun,
} from "./task-runner/task-run-review-store.js";
import {isMinimaxProvider} from "./task-runner/ai-models.js";
import {errorDetails, logError} from "./task-runner/structured-logger.js";

const ai = genkit({
  plugins: [
    // googleAI(),
    ...(isMinimaxProvider() ? [openAICompatible({
      name: "minimax",
      apiKey: requiredEnv("MINIMAX_API_KEY"),
      baseURL: requiredEnv("MINIMAX_BASE_URL"),
    })] : []),
  ],
});

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (value) return value;
  throw new Error(`${name} is required when AI_PROVIDER=minimax.`);
}

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
      );
      title = taskDefinition.title;
      const teamId = teamIdFromContext(runtime.context);
      const run = await enqueueTaskRun({
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
  {authPolicy: isSignedIn()},
  taskDefinitionFlow,
);

export const reviewTaskRunFlow = ai.defineFlow(
  {
    name: "reviewTaskRunFlow",
    inputSchema: reviewTaskRunInputSchema,
    outputSchema: reviewTaskRunOutputSchema,
  },
  async (input, runtime) => {
    const teamId = teamIdFromContext(runtime.context);
    const reviewableRun = await loadReviewableRun(teamId, input.runId);
    if (input.decision === "reject") {
      await rejectTaskRun(teamId, reviewableRun.run.runId);
      return {runId: input.runId, status: "rejected" as const};
    }
    await approveTaskRun(teamId, reviewableRun.run.runId, input.output);
    return {runId: input.runId, status: "queued" as const};
  },
);

export const reviewTaskRun = onCallGenkit(
  {authPolicy: isSignedIn()},
  reviewTaskRunFlow,
);

export const runTaskDefinitionWorker = onDocumentCreated(
  "teams/{teamId}/taskRuns/{runId}",
  async (event) => {
    const teamId = event.params.teamId;
    const run = runFromDocument(event.data?.data() ?? {});
    try {
      await markRunStarted(teamId, run.runId);
      const taskDefinition = await loadTaskDefinitionForTeam(
        teamId,
        run.taskId,
      );
      const output = await executeTaskGraph(ai, {
        taskDefinition,
        context: run.context,
      });
      if (output.status === "waitingForApproval") {
        await markRunWaitingForApproval(teamId, run, output);
        return;
      }
      await markRunSucceeded(teamId, run, output);
    } catch (error) {
      logError("run_task_definition_worker.failed", {
        taskId: run.taskId,
        runId: run.runId,
        error: errorDetails(error),
      });
      await markRunFailed(teamId, run, error);
    }
  },
);

export const resumeApprovedTaskRunWorker = onDocumentUpdated(
  "teams/{teamId}/taskRuns/{runId}",
  async (event) => {
    const before = event.data?.before.data() ?? {};
    const after = event.data?.after.data() ?? {};
    if (!shouldResumeApprovedRun(before.status, after.status)) return;
    const run = runFromDocument(after);
    const resumeState = taskResumeStateSchema.parse(after.resumeState);
    const approvedOutput = String(after.approvedOutput ?? "");
    await continueApprovedRun(
      event.params.teamId,
      run,
      resumeState,
      approvedOutput,
    );
  },
);

async function continueApprovedRun(
  teamId: string,
  run: ReturnType<typeof runFromDocument>,
  resumeState: TaskResumeState,
  approvedOutput: string,
) {
  try {
    await markRunStarted(teamId, run.runId);
    const taskDefinition = await loadTaskDefinitionForTeam(teamId, run.taskId);
    const output = await resumeTaskGraph(
      ai,
      {taskDefinition, context: run.context},
      resumeState,
      approvedOutput,
    );
    if (output.status === "waitingForApproval") {
      await markRunWaitingForApproval(teamId, run, output);
      return;
    }
    await markRunSucceeded(teamId, run, output);
  } catch (error) {
    await markRunFailed(teamId, run, error);
    throw error;
  }
}

function shouldResumeApprovedRun(beforeStatus: unknown, afterStatus: unknown) {
  return beforeStatus === "waitingForApproval" && afterStatus === "queued";
}

function teamIdFromContext(context: unknown): string {
  const auth = (context as {auth?: {uid?: string}} | undefined)?.auth;
  if (!auth?.uid) throw new Error("Auth context is missing.");
  return `personal_${auth.uid}`;
}
