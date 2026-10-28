import {z, type ModelArgument} from "genkit";
import {type SubagentSpec} from "../../../../../assistant/infrastructure/genkit/subagents/subagent-tool.js";
import {PromptBuilder} from "../../../../../language_models/domain/prompting/prompt-builder.js";
import {novooaProductKnowledge} from "./novooa-product-knowledge.js";

export const requirementsAnalysisInputSchema = z.object({
  wunsch: z.string().min(1).max(4000).describe("Der Automatisierungswunsch in den Worten der Nutzerin."),
  kontext: z.string().max(4000).optional().describe("Relevante Details aus dem bisherigen Gespräch."),
});

export const requirementsProfileSchema = z.object({
  ziel: z.string(),
  ausloeser: z.string().optional(),
  schritte: z.array(z.object({
    beschreibung: z.string(),
    baustein: z.string(),
    umsetzbar: z.boolean().describe("true if the building block is [addable]."),
  })).max(12),
  offeneFragen: z.array(z.string()).max(5),
  benoetigtModell: z.boolean(),
  benoetigtScript: z.boolean(),
});

export function requirementsAnalysisSubagentSpec(
  model: ModelArgument,
): SubagentSpec<typeof requirementsAnalysisInputSchema, typeof requirementsProfileSchema> {
  return {
    name: "anforderungsanalyse",
    description: "Analysiert einen Automatisierungswunsch und zerlegt ihn in novooa-Bausteine. " +
      "Liefert Ziel, Auslöser, Schritte, offene Fragen und ob ein ML-Modell oder Python-Script nötig ist.",
    model,
    instructions,
    tools: [],
    inputSchema: requirementsAnalysisInputSchema,
    outputSchema: requirementsProfileSchema,
    maxTurns: 1,
  };
}

const instructions = PromptBuilder.create()
  .role("You are novooa's requirements analyst. Break the wish in the input down into a small, sensible sequence of building blocks.")
  .rule("Use only building blocks from the product knowledge and never invent features.")
  .rule("Prefer [addable] building blocks; mark others with umsetzbar=false.")
  .rule("Set benoetigtModell=true if a step needs an ONNX model (e.g. classify images, read text from images, detect sentiment).")
  .rule("Set benoetigtScript=true if data must be calculated, transformed or checked and a prompt would be too unreliable for it.")
  .rule("Ask offeneFragen only if no sensible plan is possible without an answer.")
  .reference("product_knowledge", novooaProductKnowledge);
