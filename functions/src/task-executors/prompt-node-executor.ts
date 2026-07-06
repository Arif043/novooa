import { z, type Genkit } from "genkit";
import {modelLogContext, textModel} from "../task-runner/ai-models.js";
import {
  formatModelCallFinished,
  formatModelCallStarted,
  logReadableInfo,
} from "../task-runner/structured-logger.js";

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

  const prompt = promptTurn(input);
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label: "Prompt / Text",
    model: modelLogContext(),
    prompt,
  }));
  const response = await ai.generate({model: textModel(), prompt});
  logReadableInfo(formatModelCallFinished({
    label: "Prompt / Text",
    durationMs: Date.now() - startedAt,
    text: response.text,
  }));
  return {answer: response.text};
}

async function executeDecisionPrompt(
  ai: Genkit,
  input: PromptNodeInput,
): Promise<PromptNodeOutput> {
  if (input.choices.length === 0) {
    throw new Error("Decision prompt requires at least one choice.");
  }
  const prompt = promptTurn(input);
  const schema = z.object({
    answer: z.enum(input.choices as [string, ...string[]]),
  });
  const decision = await generateDecision(ai, prompt, schema);
  const answer = decision.output?.answer;
  if (answer === undefined) {
    throw new Error(`Decision prompt returned no structured answer: ${decision.text}`);
  }
  return {answer};
}

async function generateDecision(
  ai: Genkit,
  prompt: string,
  schema: z.ZodObject<{answer: z.ZodEnum<[string, ...string[]]>}>,
) {
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label: "Prompt / Entscheidung",
    model: modelLogContext(),
    prompt,
    outputSchema: "answer: enum",
  }));
  const response = await ai.generate({
    model: textModel(),
    prompt,
    output: {schema},
  });
  logReadableInfo(formatModelCallFinished({
    label: "Prompt / Entscheidung",
    durationMs: Date.now() - startedAt,
    text: response.text,
    output: response.output,
  }));
  return response;
}

function promptTurn(input: PromptNodeInput): string {
  const parts = [input.instruction];
  if (input.context.trim().length > 0) parts.push(`Kontext:\n${input.context}`);
  if (input.outputType === "decision") {
    parts.push(`Antworte nur mit einer Option: ${input.choices.join(", ")}`);
  }
  return parts.join("\n\n");
}
