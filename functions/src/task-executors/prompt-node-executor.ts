import { z, type Genkit } from "genkit";
import {modelLogContext, textModel} from "../task-runner/ai-models.js";

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
  console.log("Prompt node input.", {
    ...input,
    model: modelLogContext(),
  });
  if (input.outputType === "decision") {
    return executeDecisionPrompt(ai, input);
  }

  const prompt = promptTurn(input);
  try {
    const response = await ai.generate({
      model: textModel(),
      prompt,
    });

    console.log("Prompt node text response.", {
      text: response.text,
      model: modelLogContext(),
    });
    return { answer: response.text };
  } catch (error) {
    console.error("Prompt node text generation failed.", {
      input,
      prompt,
      model: modelLogContext(),
      error: errorDetails(error),
    });
    throw error;
  }
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
  console.log("Prompt node decision request.", {
    prompt,
    choices: input.choices,
    model: modelLogContext(),
  });
  const decision = await generateDecision(ai, input, prompt, schema);
  console.log("Prompt node decision raw response.", {
    text: decision.text,
    output: decision.output,
  });
  const answer = decision.output?.answer;
  if (answer === undefined) {
    throw new Error(`Decision prompt returned no structured answer: ${decision.text}`);
  }
  console.log("Prompt node decision answer.", {answer});
  return {answer};
}

async function generateDecision(
  ai: Genkit,
  input: PromptNodeInput,
  prompt: string,
  schema: z.ZodObject<{answer: z.ZodEnum<[string, ...string[]]>}>,
) {
  try {
    return await ai.generate({
      model: textModel(),
      prompt,
      output: {schema},
    });
  } catch (error) {
    console.error("Prompt node decision generation failed.", {
      input,
      prompt,
      choices: input.choices,
      model: modelLogContext(),
      error: errorDetails(error),
    });
    throw error;
  }
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

function errorDetails(error: unknown) {
  if (error instanceof Error) {
    return {
      name: error.name,
      message: error.message,
      stack: error.stack,
    };
  }
  return error;
}
