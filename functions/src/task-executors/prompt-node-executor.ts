import { z, type Genkit } from "genkit";
import { googleAI } from "@genkit-ai/google-genai";

export type PromptNodeOutputType = "text" | "decision";

export type PromptNodeInput = {
  instruction: string;
  context: string;
  outputType: PromptNodeOutputType;
  choices: string[];
};

export type PromptNodeOutput = {
  answer: string;
};

export async function executePromptNode(
  ai: Genkit,
  input: PromptNodeInput,
): Promise<PromptNodeOutput> {
  if (input.outputType === "decision") {
    return executeDecisionPrompt(ai, input);
  }

  const response = await ai.generate({
    model: googleAI.model("gemini-2.5-flash-lite"),
    prompt: promptTurn(input),
  });

  return { answer: response.text };
}

async function executeDecisionPrompt(
  ai: Genkit,
  input: PromptNodeInput,
): Promise<PromptNodeOutput> {
  if (input.choices.length === 0) {
    throw new Error("Decision prompt requires at least one choice.");
  }
  const decision = await ai.generate({
    model: googleAI.model("gemini-2.5-flash-lite"),
    prompt: promptTurn(input),
    output: {
      schema: z.object({
        answer: z.enum(input.choices as [string, ...string[]]),
      }),
    },
  });
  const answer = decision.output?.answer;
  if (answer === undefined) {
    throw new Error(`Decision prompt returned no structured answer: ${decision.text}`);
  }
  console.log(`Decision: ${answer}`);
  return {answer};
}

function promptTurn(input: PromptNodeInput): string {
  const parts = [input.instruction];
  if (input.context.trim().length > 0) parts.push(`Kontext:\n${input.context}`);
  if (input.outputType === "decision") {
    parts.push(`Antworte nur mit einer Option: ${input.choices.join(", ")}`);
  }
  const res = parts.join("\n\n");
  console.log(`Prompt: ${res}`);
  return res;
}
