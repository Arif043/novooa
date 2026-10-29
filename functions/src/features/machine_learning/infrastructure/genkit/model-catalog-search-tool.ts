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
  title: z.string(),
  description: z.string(),
  task: z.string(),
  topics: z.array(z.string()),
  languages: z.array(z.string()),
  inputs: z.array(z.string()),
  outputs: z.array(z.string()),
  origin: z.enum(["global", "team"]),
});

/** Lesendes Tool: durchsucht den Modellkatalog; Team-Modelle nur, wenn ein Team bekannt ist. */
export function defineModelCatalogSearchTool(
  ai: Pick<Genkit, "dynamicTool">,
  dependencies: ModelCatalogSearchToolDependencies,
): ToolAction {
  return ai.dynamicTool(
    {
      name: "searchModels",
      description: "Searches the model catalog for ML models (task, languages, search terms). "
        + "Search terms also match subject topics including parent topics and synonyms, e.g. \"Tiere\" (animals) or \"Rechnung\" (invoice).",
      inputSchema: z.object({
        task: z.enum(modelTasks).optional(),
        languages: z.array(z.string().max(20)).max(5).optional(),
        searchTerms: z.string().max(200).optional(),
      }),
      outputSchema: z.object({hits: z.array(hitSchema)}),
    },
    async ({task, languages, searchTerms}, options) => {
      const criteria = new ModelSearchCriteria(task ?? null, languages ?? [], searchTerms ?? "", maxModelSearchResults);
      const teamId = await dependencies.teamIdForActor(assistantActorIdFromContext(options.context));
      const {entries, vocabulary} = await dependencies.searchModelCatalog.execute(criteria, teamId);
      return {hits: entries.map((entry) => modelSearchHitFrom(entry, vocabulary))};
    },
  ) as ToolAction;
}
