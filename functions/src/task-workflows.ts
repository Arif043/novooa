import {genkit} from "genkit";
import {openAICompatible} from "@genkit-ai/compat-oai";
import {executeTaskGraph} from "./task-runner/task-graph-runner.js";
import {
  runTaskDefinitionInputSchema,
  runTaskDefinitionOutputSchema,
} from "./task-runner/task-definition.js";
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

export const runTaskDefinitionFlow = ai.defineFlow(
  {
    name: "runTaskDefinitionFlow",
    inputSchema: runTaskDefinitionInputSchema,
    outputSchema: runTaskDefinitionOutputSchema,
  },
  async (input) => {
    try {
      return await executeTaskGraph(ai, input);
    } catch (error) {
      logError("run_task_definition_flow.failed", {
        taskId: input.taskDefinition.id,
        title: input.taskDefinition.title,
        error: errorDetails(error),
      });
      throw error;
    }
  },
);
