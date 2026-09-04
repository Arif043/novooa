import {type IterativeRefinementRequest} from "../../../domain/entities/iterative-refinement-execution.js";

type EvaluationView = {
  critique: string;
  satisfied: boolean;
};

export function formatRefinementStarted(
  input: IterativeRefinementRequest,
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

export function formatEvaluation(
  iteration: number,
  evaluation: EvaluationView,
): string {
  return [
    `[Iteration ${iteration}] Bewertung`,
    `Erfüllt: ${evaluation.satisfied ? "ja" : "nein"}`,
    `Kritik: ${preview(evaluation.critique)}`,
  ].join("\n");
}

export function formatImprovement(
  iteration: number,
  answer: string,
): string {
  return [
    `[Iteration ${iteration}] Optimierung`,
    `Neuer Entwurf: ${answer.length} Zeichen`,
    `Vorschau: ${preview(answer)}`,
  ].join("\n");
}

export function formatRefinementFinished(
  iterations: number,
  answer: string,
): string {
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
