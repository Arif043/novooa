import { z, type Genkit } from "genkit";
import { googleAI } from "@genkit-ai/google-genai";

export type PromptOutputType = "text" | "decision";

export type PromptNodeInput = {
  instruction: string;
  context: string;
  outputType: PromptOutputType;
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
    const decision = await ai.generate({
      model: googleAI.model("gemini-2.5-flash-lite"),
      prompt: promptTurn(input),
      output: {
        schema: z.object({
          answer: z.enum(input.choices as [string, ...string[]]),
        }),
      }
    });
    console.log(`Decision: ${decision.text}`);

    if (!input.choices.includes(decision.text)) {
      throw new Error(`Invalid decision: ${decision.text}`);
    }
    return { answer: decision.text };
  }

  const response = await ai.generate({
    model: googleAI.model("gemini-2.5-flash-lite"),
    prompt: promptTurn(input),
  });

  return { answer: response.text };
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
