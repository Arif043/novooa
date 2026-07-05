import {genkit} from "genkit";
import {googleAI} from "@genkit-ai/google-genai";
import {openAICompatible} from "@genkit-ai/compat-oai";
import {executeTaskGraph} from "./task-runner/task-graph-runner.js";
import {
  runTaskDefinitionInputSchema,
  runTaskDefinitionOutputSchema,
} from "./task-runner/task-definition.js";
import {isMinimaxProvider} from "./task-runner/ai-models.js";

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
  async (input) => executeTaskGraph(ai, input),
);
