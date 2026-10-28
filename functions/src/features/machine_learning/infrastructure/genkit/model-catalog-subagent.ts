import {z, type ModelArgument, type ToolArgument} from "genkit";
import {type SubagentSpec} from "../../../assistant/infrastructure/genkit/subagents/subagent-tool.js";
import {PromptBuilder} from "../../../language_models/domain/prompting/prompt-builder.js";

export const modelCatalogSubagentInputSchema = z.object({
  bedarf: z.string().min(1).max(2000).describe("Was das Modell fachlich leisten soll, inkl. Eingabeart."),
  sprache: z.string().max(20).optional().describe("Sprache der Inhalte, z. B. de."),
});

export const modelCatalogSubagentOutputSchema = z.object({
  vorschlaege: z.array(z.object({
    modelId: z.string(),
    titel: z.string(),
    begruendung: z.string(),
    eingaben: z.array(z.string()),
    ausgaben: z.array(z.string()),
  })).max(3),
  hinweis: z.string().optional(),
});

export function modelCatalogSubagentSpec(
  model: ModelArgument,
  searchTool: ToolArgument,
): SubagentSpec<typeof modelCatalogSubagentInputSchema, typeof modelCatalogSubagentOutputSchema> {
  return {
    name: "modellkatalog_suche",
    description: "Findet passende ML-Modelle im globalen Modellkatalog (und eigene Team-Modelle) " +
      "für den Baustein modelInference. Liefert höchstens drei begründete Vorschläge.",
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
  .rule("Use only the tool sucheModelle. If there are few hits, try a suitable model task or other search terms, including English ones.")
  .rule("Suggest only models the tool returned; take modelId, eingaben and ausgaben unchanged.")
  .rule("Explain briefly in begruendung why the inputs and outputs fit the need.")
  .rule("If no model fits, return an empty list and explain in hinweis what is missing.");
