import {z, type Genkit} from "genkit";
import {knowledgeNoteNeighbours} from "../../domain/services/knowledge-note-neighbours.js";
import {
  limitedContent,
  teamIdForContext,
  type KnowledgeNoteToolDependencies,
} from "./knowledge-note-tool-support.js";

const contentLength = 12000;

const noteReferenceSchema = z.object({id: z.string(), title: z.string()});

const noteSchema = z.object({
  id: z.string(),
  title: z.string(),
  path: z.string(),
  content: z.string(),
  links: z.array(noteReferenceSchema),
  backlinks: z.array(noteReferenceSchema),
});

export function defineReadKnowledgeNoteTool(ai: Genkit, dependencies: KnowledgeNoteToolDependencies) {
  return ai.defineTool(
    {
      name: "readKnowledgeNote",
      description: "Reads the Markdown content of a note by its ID, together with the notes it links to (links) and the notes that link to it (backlinks).",
      inputSchema: z.object({noteId: z.string().min(1).max(200)}),
      outputSchema: z.object({found: z.boolean(), note: noteSchema.nullable()}),
    },
    async ({noteId}, options) => {
      const teamId = await teamIdForContext(options.context, dependencies.teamContextStore);
      const notes = await dependencies.noteStore.listNotes(teamId);
      const note = notes.find((candidate) => candidate.id === noteId);
      if (note === undefined) return {found: false, note: null};
      return {
        found: true,
        note: {
          ...note,
          content: limitedContent(note.content, contentLength),
          ...knowledgeNoteNeighbours(note, notes),
        },
      };
    },
  );
}
