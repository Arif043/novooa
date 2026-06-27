import {type Genkit} from "genkit";
import {googleAI} from "@genkit-ai/google-genai";

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
  const response = await ai.generate({
    model: googleAI.model("gemini-2.5-flash-lite"),
    prompt: promptTurn(input),
    config: {temperature: 0.3},
  });

  return {answer: response.text};
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
