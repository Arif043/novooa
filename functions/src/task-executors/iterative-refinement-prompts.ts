import {type IterativeRefinementNodeInput} from "./iterative-refinement-node-executor.js";

export function evaluationPrompt(
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

export function improvementPrompt(
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
