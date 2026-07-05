import {z, type Genkit} from "genkit";
import {modelLogContext, reasoningModel} from "../task-runner/ai-models.js";

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

type Evaluation = {
  critique: string;
  satisfied: boolean;
};

const evaluationSchema = z.object({
  critique: z.string(),
  satisfied: z.boolean(),
});

export async function executeIterativeRefinementNode(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
): Promise<IterativeRefinementNodeOutput> {
  const maxIterations = boundedIterations(input.maxIterations);
  let answer = await initialDraft(ai, input);
  let iterations = 0;

  for (; iterations < maxIterations; iterations += 1) {
    const evaluation = await evaluateDraft(ai, input, answer, iterations + 1);
    console.log("Iterative refinement evaluation.", {iterations, evaluation});
    if (evaluation.satisfied) break;
    answer = await improveDraft(ai, input, answer, evaluation.critique);
    console.log("Iterative refinement improved draft.", {iterations, answer});
  }

  return {answer, iterations};
}

async function initialDraft(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
): Promise<string> {
  if (input.draft.trim().length > 0) return input.draft;
  const response = await ai.generate({
    model: reasoningModel(),
    prompt: initialDraftPrompt(input),
  });
  console.log("Iterative refinement initial draft.", {
    text: response.text,
    model: modelLogContext(),
  });
  return response.text;
}

async function evaluateDraft(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
  draft: string,
  iteration: number,
): Promise<Evaluation> {
  try {
    return await structuredEvaluation(ai, input, draft, iteration);
  } catch (error) {
    console.error("Structured refinement evaluation failed.", {
      iteration,
      error: errorDetails(error),
    });
    return textEvaluationFallback(ai, input, draft, iteration);
  }
}

async function structuredEvaluation(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
  draft: string,
  iteration: number,
): Promise<Evaluation> {
  const response = await ai.generate({
    model: reasoningModel(),
    prompt: evaluationPrompt(input, draft, iteration),
    output: {schema: evaluationSchema},
  });
  if (!response.output) throw new Error("Evaluation returned no output.");
  return response.output;
}

async function textEvaluationFallback(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
  draft: string,
  iteration: number,
): Promise<Evaluation> {
  const response = await ai.generate({
    model: reasoningModel(),
    prompt: `${evaluationPrompt(input, draft, iteration)}\n\nAntwort als JSON.`,
  });
  return parseEvaluation(response.text);
}

async function improveDraft(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
  draft: string,
  critique: string,
): Promise<string> {
  const response = await ai.generate({
    model: reasoningModel(),
    prompt: improvementPrompt(input, draft, critique),
    config: {temperature: 0.4},
  });
  return response.text;
}

function parseEvaluation(text: string): Evaluation {
  const parsed = evaluationSchema.safeParse(jsonFrom(text));
  if (parsed.success) return parsed.data;
  return {critique: text, satisfied: false};
}

function jsonFrom(text: string) {
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) return {};
  try {
    return JSON.parse(match[0]);
  } catch {
    return {};
  }
}

function initialDraftPrompt(input: IterativeRefinementNodeInput): string {
  return [
    `Ziel: ${input.objective || "Verbessere den gegebenen Arbeitsstand."}`,
    `Kriterien: ${input.critiquePrompt}`,
    "Erstelle einen ersten präzisen Entwurf.",
  ].join("\n\n");
}

function evaluationPrompt(
  input: IterativeRefinementNodeInput,
  draft: string,
  iteration: number,
): string {
  return [
    `Iteration: ${iteration}`,
    `Ziel: ${input.objective || "Qualität des Ergebnisses verbessern."}`,
    `Kriterien: ${input.critiquePrompt}`,
    `Entwurf:\n${draft}`,
    "Bewerte, ob der Entwurf die Kriterien erfüllt.",
    'Gib JSON zurück: {"critique": "...", "satisfied": true|false}',
  ].join("\n\n");
}

function improvementPrompt(
  input: IterativeRefinementNodeInput,
  draft: string,
  critique: string,
): string {
  return [
    `Ziel: ${input.objective || "Verbessere den Entwurf."}`,
    `Kriterien: ${input.critiquePrompt}`,
    `Aktueller Entwurf:\n${draft}`,
    `Feedback:\n${critique}`,
    "Überarbeite den Entwurf. Gib nur die verbesserte Fassung zurück.",
  ].join("\n\n");
}

function boundedIterations(value: number): number {
  return Math.min(Math.max(value, 1), 5);
}

function errorDetails(error: unknown) {
  if (error instanceof Error) {
    return {name: error.name, message: error.message, stack: error.stack};
  }
  return error;
}
