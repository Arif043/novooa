import {z, type Genkit} from "genkit";
import {searchKnowledgeNotes} from "../../domain/services/knowledge-note-search.js";
import {
  limitedContent,
  teamIdForContext,
  type KnowledgeNoteToolDependencies,
} from "./knowledge-note-tool-support.js";

const maximumResults = 20;
const excerptLength = 700;

const noteSummarySchema = z.object({
  id: z.string(),
  title: z.string(),
  path: z.string(),
  excerpt: z.string(),
});

export function defineSearchKnowledgeNotesTool(ai: Genkit, dependencies: KnowledgeNoteToolDependencies) {
  return ai.defineTool(
    {
      name: "searchKnowledgeNotes",
      description: "Searches title, path and content of all notes in the current team's knowledge base; title matches come first.",
      inputSchema: z.object({query: z.string().max(200).optional()}),
      outputSchema: z.object({notes: z.array(noteSummarySchema)}),
    },
    async ({query}, options) => {
      const teamId = await teamIdForContext(options.context, dependencies.teamContextStore);
      const notes = await dependencies.noteStore.listNotes(teamId);
      return {
        notes: searchKnowledgeNotes(notes, query ?? "", maximumResults).map((note) => ({
          id: note.id,
          title: note.title,
          path: note.path,
          excerpt: limitedContent(note.content, excerptLength),
        })),
      };
    },
  );
}
