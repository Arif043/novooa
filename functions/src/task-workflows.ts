import {genkit} from "genkit";
import {googleAI} from "@genkit-ai/google-genai";
import {executeTaskGraph} from "./task-runner/task-graph-runner.js";
import {
  runTaskDefinitionInputSchema,
  runTaskDefinitionOutputSchema,
} from "./task-runner/task-definition.js";

const ai = genkit({
  plugins: [googleAI()],
});

export const runTaskDefinitionFlow = ai.defineFlow(
  {
    name: "runTaskDefinitionFlow",
    inputSchema: runTaskDefinitionInputSchema,
    outputSchema: runTaskDefinitionOutputSchema,
  },
  async (input) => executeTaskGraph(ai, input),
);
