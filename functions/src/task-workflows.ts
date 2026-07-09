import {genkit} from "genkit";
import {openAICompatible} from "@genkit-ai/compat-oai";
import {isSignedIn, onCallGenkit} from "firebase-functions/v2/https";
import {executeTaskGraph} from "./task-runner/task-graph-runner.js";
import {
  runTaskDefinitionInputSchema,
  runTaskDefinitionOutputSchema,
} from "./task-runner/task-definition.js";
import {loadTaskDefinition} from "./task-runner/task-definition-loader.js";
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
      return await executeTaskGraph(ai, {
        taskDefinition,
        context: input.context,
      });
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
