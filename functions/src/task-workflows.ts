import {genkit, z} from "genkit";
import {googleAI} from "@genkit-ai/google-genai";

const ai = genkit({
  plugins: [googleAI()],
});

const conditionalBranchSchema = z.object({
  nodeId: z.string(),
  condition: z.string(),
});

export const conditionalTaskFlow = ai.defineFlow(
  {
    name: "conditionalTaskFlow",
    inputSchema: z.object({
      context: z.string(),
      branches: z.array(conditionalBranchSchema),
      fallbackNodeId: z.string(),
    }),
    outputSchema: z.object({
      selectedNodeId: z.string(),
      reason: z.string(),
    }),
  },
  async (input) => {
    const matchingBranch = input.branches.find((branch) => {
      return input.context.toLowerCase().includes(branch.condition.toLowerCase());
    });

    return {
      selectedNodeId: matchingBranch?.nodeId ?? input.fallbackNodeId,
      reason: matchingBranch
        ? `Matched condition: ${matchingBranch.condition}`
        : "No condition matched. Used fallback branch.",
    };
  },
);

export const iterativeRefinementTaskFlow = ai.defineFlow(
  {
    name: "iterativeRefinementTaskFlow",
    inputSchema: z.object({
      objective: z.string(),
      draft: z.string(),
      critiquePrompt: z.string(),
      maxIterations: z.number().min(1).max(5).default(2),
    }),
    outputSchema: z.object({
      answer: z.string(),
      iterations: z.number(),
    }),
  },
  async (input) => {
    let answer = input.draft;

    for (let iteration = 0; iteration < input.maxIterations; iteration += 1) {
      const response = await ai.generate({
        model: googleAI.model("gemini-2.5-flash"),
        prompt: refinementPrompt(input.objective, answer, input.critiquePrompt),
        config: {temperature: 0.4},
      });
      answer = response.text;
    }

    return {
      answer,
      iterations: input.maxIterations,
    };
  },
);

function refinementPrompt(
  objective: string,
  draft: string,
  critiquePrompt: string,
): string {
  return [
    `Objective: ${objective}`,
    `Current draft: ${draft}`,
    `Critique criteria: ${critiquePrompt}`,
    "Return only the improved answer.",
  ].join("\n\n");
}
