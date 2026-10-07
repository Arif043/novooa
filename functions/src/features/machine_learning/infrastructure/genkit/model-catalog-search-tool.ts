import {z, type Genkit, type ToolAction} from "genkit";
import {assistantActorIdFromContext} from "../../../assistant/infrastructure/genkit/assistant-genkit-context.js";
import {maxModelSearchResults, ModelSearchCriteria} from "../../domain/entities/model-search-criteria.js";
import {modelTasks} from "../../domain/entities/model-task.js";
import {type SearchModelCatalog} from "../../domain/usecases/search-model-catalog.js";
import {modelSearchHitFrom} from "./model-search-hit.js";

export type TeamIdForActor = (actorId: string) => Promise<string | null>;

export type ModelCatalogSearchToolDependencies = {
  searchModelCatalog: SearchModelCatalog;
  teamIdForActor: TeamIdForActor;
};

const hitSchema = z.object({
  modelId: z.string(),
  titel: z.string(),
  beschreibung: z.string(),
  aufgabe: z.string(),
  sprachen: z.array(z.string()),
  eingaben: z.array(z.string()),
  ausgaben: z.array(z.string()),
  herkunft: z.enum(["global", "team"]),
});

/** Lesendes Tool: durchsucht den Modellkatalog; Team-Modelle nur, wenn ein Team bekannt ist. */
export function defineModelCatalogSearchTool(
  ai: Pick<Genkit, "dynamicTool">,
  dependencies: ModelCatalogSearchToolDependencies,
): ToolAction {
  return ai.dynamicTool(
    {
      name: "sucheModelle",
      description: "Durchsucht den Modellkatalog nach ML-Modellen (Aufgabe, Sprache, Suchbegriffe).",
      inputSchema: z.object({
        aufgabe: z.enum(modelTasks).optional(),
        sprachen: z.array(z.string().max(20)).max(5).optional(),
        suchbegriffe: z.string().max(200).optional(),
      }),
      outputSchema: z.object({treffer: z.array(hitSchema)}),
    },
    async ({aufgabe, sprachen, suchbegriffe}, options) => {
      const criteria = new ModelSearchCriteria(aufgabe ?? null, sprachen ?? [], suchbegriffe ?? "", maxModelSearchResults);
      const teamId = await dependencies.teamIdForActor(assistantActorIdFromContext(options.context));
      const entries = await dependencies.searchModelCatalog.execute(criteria, teamId);
      return {treffer: entries.map(modelSearchHitFrom)};
    },
  ) as ToolAction;
}
