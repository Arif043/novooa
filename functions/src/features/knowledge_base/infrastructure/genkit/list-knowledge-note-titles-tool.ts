import {z, type Genkit} from "genkit";
import {knowledgeNoteOverview} from "../../domain/services/knowledge-note-overview.js";
import {teamIdForContext, type KnowledgeNoteToolDependencies} from "./knowledge-note-tool-support.js";

/** Reicht für einige hundert Notizen und hält die Antwort im Kontextfenster kleiner Modelle. */
const maximumEntries = 500;

const overviewEntrySchema = z.object({
  id: z.string(),
  title: z.string(),
  links: z.number().int(),
  backlinks: z.number().int(),
});

export function defineListKnowledgeNoteTitlesTool(ai: Genkit, dependencies: KnowledgeNoteToolDependencies) {
  return ai.defineTool(
    {
      name: "listKnowledgeNoteTitles",
      description: "Lists all notes of the current team's knowledge base with ID, title, the number of notes each one "
        + "links to (links) and the number of notes linking to it (backlinks), without content. "
        + "Notes with 0 backlinks are orphans. Use it for an overview of the Zettelkasten.",
      inputSchema: z.object({}),
      outputSchema: z.object({
        total: z.number().int(),
        truncated: z.boolean(),
        notes: z.array(overviewEntrySchema),
      }),
    },
    async (_input, options) => {
      const teamId = await teamIdForContext(options.context, dependencies.teamContextStore);
      const overview = knowledgeNoteOverview(await dependencies.noteStore.listNotes(teamId));
      return {
        total: overview.length,
        truncated: overview.length > maximumEntries,
        notes: overview.slice(0, maximumEntries),
      };
    },
  );
}
