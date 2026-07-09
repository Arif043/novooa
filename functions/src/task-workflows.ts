import {genkit} from "genkit";
import {openAICompatible} from "@genkit-ai/compat-oai";
import {isSignedIn, onCallGenkit} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {executeTaskGraph} from "./task-runner/task-graph-runner.js";
import {
  runTaskDefinitionInputSchema,
  runTaskDefinitionOutputSchema,
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
  runFromDocument,
} from "./task-runner/task-activity-logger.js";
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

function teamIdFromContext(context: unknown): string {
  const auth = (context as {auth?: {uid?: string}} | undefined)?.auth;
  if (!auth?.uid) throw new Error("Auth context is missing.");
  return `personal_${auth.uid}`;
}
