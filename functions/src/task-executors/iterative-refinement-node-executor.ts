import {type Genkit} from "genkit";
import {googleAI} from "@genkit-ai/google-genai";

export type IterativeRefinementNodeInput = {
  objective: string;
  draft: string;
  critiquePrompt: string;
  maxIterations: number;
};

export type IterativeRefinementNodeOutput = {
  answer: string;
  iterations: number;
};

export async function executeIterativeRefinementNode(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
): Promise<IterativeRefinementNodeOutput> {
  let answer = input.draft;
  const iterations = Math.min(Math.max(input.maxIterations, 1), 5);

  for (let iteration = 0; iteration < iterations; iteration += 1) {
    const response = await ai.generate({
      model: googleAI.model("gemini-2.5-flash"),
      prompt: refinementPrompt(input.objective, answer, input.critiquePrompt),
      config: {temperature: 0.4},
    });
    answer = response.text;
  }

  return {answer, iterations};
}

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
