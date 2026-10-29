import {z, type ModelArgument} from "genkit";
import {type SubagentSpec} from "../../../../../assistant/infrastructure/genkit/subagents/subagent-tool.js";
import {PromptBuilder} from "../../../../../language_models/domain/prompting/prompt-builder.js";
import {novooaProductKnowledge} from "./novooa-product-knowledge.js";

export const requirementsAnalysisInputSchema = z.object({
  request: z.string().min(1).max(4000).describe("The automation request in the user's own words."),
  context: z.string().max(4000).optional().describe("Relevant details from the conversation so far."),
});

export const requirementsProfileSchema = z.object({
  goal: z.string(),
  trigger: z.string().optional(),
  steps: z.array(z.object({
    description: z.string(),
    buildingBlock: z.string(),
    addable: z.boolean().describe("true if the building block is [addable]."),
  })).max(12),
  openQuestions: z.array(z.string()).max(5),
  needsModel: z.boolean(),
  needsScript: z.boolean(),
});

export function requirementsAnalysisSubagentSpec(
  model: ModelArgument,
): SubagentSpec<typeof requirementsAnalysisInputSchema, typeof requirementsProfileSchema> {
  return {
    name: "requirements_analysis",
    description: "Analyzes an automation request and breaks it down into novooa building blocks. " +
      "Returns goal, trigger, steps, open questions and whether an ML model or Python script is needed.",
    model,
    instructions,
    tools: [],
    inputSchema: requirementsAnalysisInputSchema,
    outputSchema: requirementsProfileSchema,
    maxTurns: 1,
  };
}

const instructions = PromptBuilder.create()
  .role("You are novooa's requirements analyst. Break the request in the input down into a small, sensible sequence of building blocks.")
  .rule("Use only building blocks from the product knowledge and never invent features.")
  .rule("Prefer [addable] building blocks; mark others with addable=false.")
  .rule("Set needsModel=true if a step needs an ONNX model (e.g. classify images, read text from images, detect sentiment).")
  .rule("Set needsScript=true if data must be calculated, transformed or checked and a prompt would be too unreliable for it.")
  .rule("Ask openQuestions only if no sensible plan is possible without an answer.")
  .reference("product_knowledge", novooaProductKnowledge);
