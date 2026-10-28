import {type GenkitBeta} from "genkit/beta";
import {type LlmGateway, type LlmStructuredField} from "../../../../language_models/domain/prompting/llm-gateway.js";
import {type GenkitLlmBinding} from "../../../../language_models/infrastructure/genkit/llm/genkit-llm-binding.js";
import {type IterativeRefinementRequest} from "../../../domain/entities/iterative-refinement-execution.js";
import {modelLogContext, reasoningModel} from "../runner/ai-models.js";
import {aiTurnMiddleware} from "../runner/node-attachment-genkit.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {type Evaluation, evaluationSchema, parseEvaluation} from "./iterative-refinement-evaluation.js";
import {evaluationPrompt, evaluationTextPrompt, improvementPrompt} from "./iterative-refinement-prompts.js";

/** Modell, Werkzeuge und Gateway eines Laufs der Iterativen Verfeinerung. */
export type RefinementCall = {
  ai: GenkitBeta;
  gateway: LlmGateway<GenkitLlmBinding>;
  workspace?: NodeAttachmentWorkspace;
};

const evaluationFields: LlmStructuredField[] = [
  {name: "critique", type: "string", description: "Concrete assessment of the draft against the criteria."},
  {name: "satisfied", type: "boolean", description: "Whether the draft meets every criterion."},
];

/** Bewertung mit Ausgabeschema; wirft, wenn das Modell keine gültige Bewertung liefert. */
export async function structuredEvaluation(
  call: RefinementCall, input: IterativeRefinementRequest, draft: string, iteration: number,
): Promise<Evaluation> {
  const response = await call.gateway.generate({
    binding: bindingFor(call), prompt: evaluationPrompt(input, draft, call.workspace),
    label: labelFor(input, `Bewertung ${iteration}`), output: {kind: "structured", fields: evaluationFields},
  });
  const evaluation = evaluationSchema.safeParse(response.data);
  if (!evaluation.success) throw new Error("Evaluation returned no output.");
  return evaluation.data;
}

/** Rückfall für Modelle ohne strukturierte Ausgabe: JSON aus dem Text, sonst gilt der Text als Kritik. */
export async function textEvaluation(
  call: RefinementCall, input: IterativeRefinementRequest, draft: string, iteration: number,
): Promise<Evaluation> {
  const response = await call.gateway.generate({
    binding: bindingFor(call), prompt: evaluationTextPrompt(input, draft, call.workspace),
    label: labelFor(input, `Bewertungs-Fallback ${iteration}`), output: {kind: "text"},
  });
  return parseEvaluation(response.text);
}

/** Überarbeitet den Entwurf; etwas Temperatur lässt neue Formulierungen zu. */
export async function improvement(
  call: RefinementCall, input: IterativeRefinementRequest, draft: string, critique: string,
): Promise<string> {
  const response = await call.gateway.generate({
    binding: bindingFor(call, {temperature: 0.4}), prompt: improvementPrompt(input, draft, critique, call.workspace),
    label: labelFor(input, "Optimierung"), output: {kind: "text"},
  });
  return response.text;
}

function bindingFor(call: RefinementCall, config: Record<string, unknown> = {}): GenkitLlmBinding {
  return {ai: call.ai, model: reasoningModel(), config, logContext: modelLogContext(), use: aiTurnMiddleware(call.workspace)};
}

function labelFor(input: IterativeRefinementRequest, step: string): string {
  const label = `Iterative Verfeinerung / ${step}`;
  return input.employee ? `${label} (Mitarbeiter: ${input.employee.name})` : label;
}
