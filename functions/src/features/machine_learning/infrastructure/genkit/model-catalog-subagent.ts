import {z, type ModelArgument, type ToolArgument} from "genkit";
import {type SubagentSpec} from "../../../assistant/infrastructure/genkit/subagents/subagent-tool.js";
import {PromptBuilder} from "../../../language_models/domain/prompting/prompt-builder.js";

export const modelCatalogSubagentInputSchema = z.object({
  need: z.string().min(1).max(2000).describe("What the model must do functionally, including the kind of input."),
  language: z.string().max(20).optional().describe("Language of the content, e.g. de."),
});

export const modelCatalogSubagentOutputSchema = z.object({
  suggestions: z.array(z.object({
    modelId: z.string(),
    title: z.string(),
    reason: z.string(),
    inputs: z.array(z.string()),
    outputs: z.array(z.string()),
  })).max(3),
  note: z.string().optional(),
});

export function modelCatalogSubagentSpec(
  model: ModelArgument,
  searchTool: ToolArgument,
): SubagentSpec<typeof modelCatalogSubagentInputSchema, typeof modelCatalogSubagentOutputSchema> {
  return {
    name: "model_catalog_search",
    description: "Finds suitable ML models in the global model catalog (and the team's own models) " +
      "for the modelInference building block. Returns at most three justified suggestions.",
    model,
    instructions,
    tools: [searchTool],
    inputSchema: modelCatalogSubagentInputSchema,
    outputSchema: modelCatalogSubagentOutputSchema,
    maxTurns: 4,
  };
}

const instructions = PromptBuilder.create()
  .role("You are novooa's model catalog expert. Find suitable ML models for the need in the input.")
  .rule("Use only the tool searchModels. If there are few hits, try a suitable model task or other search terms, including English ones.")
  .rule("Suggest only models the tool returned; take modelId, inputs and outputs unchanged.")
  .rule("Explain briefly in reason why the inputs and outputs fit the need.")
  .rule("If no model fits, return an empty list and explain in note what is missing.");
