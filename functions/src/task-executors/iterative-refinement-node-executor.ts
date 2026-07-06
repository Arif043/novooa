import {z, type Genkit} from "genkit";
import {modelLogContext, reasoningModel} from "../task-runner/ai-models.js";
import {
  errorDetails,
  formatException,
  formatModelCallFinished,
  formatModelCallStarted,
  logError,
  logReadableError,
  logReadableInfo,
} from "../task-runner/structured-logger.js";

export type IterativeRefinementNodeInput = {
  objective: string;
  draft: string;
  optimizerPrompt: string;
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
  let answer = input.draft;
  let iterations = 0;

  logReadableInfo(formatRefinementStarted(input, maxIterations));
  for (let nextIteration = 1; nextIteration <= maxIterations; nextIteration += 1) {
    iterations = nextIteration;
    const evaluation = await evaluateDraft(ai, input, answer, nextIteration);
    logReadableInfo(formatEvaluation(nextIteration, evaluation));
    if (evaluation.satisfied) break;
    answer = await improveDraft(ai, input, answer, evaluation.critique);
    logReadableInfo(formatImprovement(nextIteration, answer));
  }

  logReadableInfo(formatRefinementFinished(iterations, answer));
  return {answer, iterations};
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
    logReadableError(formatException({
      title: "Iterative Verfeinerung: strukturierte Bewertung fehlgeschlagen",
      error,
      context: [
        `Iteration: ${iteration}`,
        "Fallback: Textbewertung wird versucht.",
      ],
    }));
    logError("iterative_refinement.structured_evaluation_exception", {
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
  const prompt = evaluationPrompt(input, draft);
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label: `Iterative Verfeinerung / Bewertung ${iteration}`,
    model: modelLogContext(),
    prompt,
    outputSchema: "critique: string, satisfied: boolean",
  }));
  const response = await ai.generate({
    model: reasoningModel(),
    prompt,
    output: {schema: evaluationSchema},
  });
  logReadableInfo(formatModelCallFinished({
    label: `Iterative Verfeinerung / Bewertung ${iteration}`,
    durationMs: Date.now() - startedAt,
    text: response.text,
    output: response.output,
  }));
  if (!response.output) throw new Error("Evaluation returned no output.");
  return response.output;
}

async function textEvaluationFallback(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
  draft: string,
  iteration: number,
): Promise<Evaluation> {
  const prompt = `${evaluationPrompt(input, draft)}\n\nAntwort als JSON.`;
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label: `Iterative Verfeinerung / Bewertungs-Fallback ${iteration}`,
    model: modelLogContext(),
    prompt,
  }));
  const response = await ai.generate({
    model: reasoningModel(),
    prompt,
  });
  logReadableInfo(formatModelCallFinished({
    label: `Iterative Verfeinerung / Bewertungs-Fallback ${iteration}`,
    durationMs: Date.now() - startedAt,
    text: response.text,
  }));
  return parseEvaluation(response.text);
}

async function improveDraft(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
  draft: string,
  critique: string,
): Promise<string> {
  const prompt = improvementPrompt(input, draft, critique);
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label: "Iterative Verfeinerung / Optimierung",
    model: modelLogContext(),
    prompt,
  }));
  const response = await ai.generate({
    model: reasoningModel(),
    prompt,
    config: {temperature: 0.4},
  });
  logReadableInfo(formatModelCallFinished({
    label: "Iterative Verfeinerung / Optimierung",
    durationMs: Date.now() - startedAt,
    text: response.text,
  }));
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

function evaluationPrompt(
  input: IterativeRefinementNodeInput,
  draft: string,
): string {
  return [
    `Ziel: ${input.objective || "Qualität des Ergebnisses verbessern."}`,
    `Kriterien: ${input.critiquePrompt}`,
    `Entwurf:\n${draft}`,
    "Bewerte, ob der Entwurf die Kriterien erfüllt.",
  ].join("\n\n");
}

function improvementPrompt(
  input: IterativeRefinementNodeInput,
  draft: string,
  critique: string,
): string {
  return [
    `Ziel: ${input.objective || "Verbessere den Entwurf."}`,
    optimizerInstruction(input),
    `Aktueller Entwurf:\n${draft}`,
    `Feedback:\n${critique}`,
    "Überarbeite den Entwurf. Gib nur die verbesserte Fassung zurück.",
  ].join("\n\n");
}

function optimizerInstruction(input: IterativeRefinementNodeInput): string {
  const prompt = input.optimizerPrompt.trim();
  return prompt.length > 0
    ? `Optimierer-Prompt:\n${prompt}`
    : "Optimierer-Prompt: Verbessere den Entwurf gezielt und präzise.";
}

function formatRefinementStarted(
  input: IterativeRefinementNodeInput,
  maxIterations: number,
): string {
  return [
    "[Iterative Verfeinerung startet]",
    `Maximale Iterationen: ${maxIterations}`,
    `Draft: ${input.draft.length} Zeichen`,
    `Optimierer-Prompt: ${input.optimizerPrompt.length} Zeichen`,
    `Kritik-Prompt: ${input.critiquePrompt.length} Zeichen`,
  ].join("\n");
}

function formatEvaluation(iteration: number, evaluation: Evaluation): string {
  return [
    `[Iteration ${iteration}] Bewertung`,
    `Erfüllt: ${evaluation.satisfied ? "ja" : "nein"}`,
    `Kritik: ${preview(evaluation.critique)}`,
  ].join("\n");
}

function formatImprovement(iteration: number, answer: string): string {
  return [
    `[Iteration ${iteration}] Optimierung`,
    `Neuer Entwurf: ${answer.length} Zeichen`,
    `Vorschau: ${preview(answer)}`,
  ].join("\n");
}

function formatRefinementFinished(iterations: number, answer: string): string {
  return [
    "[Iterative Verfeinerung beendet]",
    `Durchgeführte Iterationen: ${iterations}`,
    `Finaler Entwurf: ${answer.length} Zeichen`,
  ].join("\n");
}

function preview(text: string): string {
  const normalized = text.replace(/\s+/g, " ").trim();
  return normalized.length > 160
    ? `${normalized.slice(0, 157)}...`
    : normalized;
}

function boundedIterations(value: number): number {
  return Math.min(Math.max(value, 1), 5);
}
