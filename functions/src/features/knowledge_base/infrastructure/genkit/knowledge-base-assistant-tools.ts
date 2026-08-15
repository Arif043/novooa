import {z, type Genkit} from "genkit";
import {
  type KnowledgeBaseAssistantNote,
  type KnowledgeBaseAssistantNoteStore,
} from "../../domain/repositories/knowledge-base-assistant-note-store.js";
import {type TeamContextStore} from "../../../teams/domain/repositories/team-context-store.js";
import {
  defineExtractPageLinksTool,
  type ExtractPageLinksToolDependencies,
} from "./extract-page-links-tool.js";
import {assistantActorIdFromContext} from "./knowledge-base-assistant-runtime-context.js";

export type KnowledgeBaseAssistantToolDependencies =
  ExtractPageLinksToolDependencies & {
  noteStore: KnowledgeBaseAssistantNoteStore;
  teamContextStore: TeamContextStore;
};

export function defineKnowledgeBaseAssistantTools(
  ai: Genkit,
  dependencies: KnowledgeBaseAssistantToolDependencies,
) {
  return {
    searchKnowledgeNotes: defineSearchKnowledgeNotesTool(ai, dependencies),
    readKnowledgeNote: defineReadKnowledgeNoteTool(ai, dependencies),
    extractPageLinks: defineExtractPageLinksTool(ai, dependencies),
  };
}

function defineSearchKnowledgeNotesTool(
  ai: Genkit,
  dependencies: KnowledgeBaseAssistantToolDependencies,
) {
  return ai.defineTool(
    {
      name: "searchKnowledgeNotes",
      description: "Durchsucht Notizen der Wissensbasis des aktuellen Teams.",
      inputSchema: z.object({query: z.string().max(200).optional()}),
      outputSchema: z.object({notes: z.array(noteSummarySchema)}),
    },
    async ({query}, options) => {
      const teamId = await teamIdForContext(
        options.context,
        dependencies.teamContextStore,
      );
      const notes = await dependencies.noteStore.listNotes(teamId);
      return {
        notes: notes
            .filter((note) => matches(note, query ?? ""))
            .slice(0, 20)
            .map(summaryFor),
      };
    },
  );
}

function defineReadKnowledgeNoteTool(
  ai: Genkit,
  dependencies: KnowledgeBaseAssistantToolDependencies,
) {
  return ai.defineTool(
    {
      name: "readKnowledgeNote",
      description: "Liest den Markdown-Inhalt einer Notiz anhand ihrer ID.",
      inputSchema: z.object({noteId: z.string().min(1).max(200)}),
      outputSchema: z.object({
        found: z.boolean(),
        note: noteSchema.nullable(),
      }),
    },
    async ({noteId}, options) => {
      const teamId = await teamIdForContext(
        options.context,
        dependencies.teamContextStore,
      );
      const note = await dependencies.noteStore.findNote(teamId, noteId);
      return {found: note !== null, note: note && noteForTool(note)};
    },
  );
}

const noteSummarySchema = z.object({
  id: z.string(),
  title: z.string(),
  path: z.string(),
  excerpt: z.string(),
});

const noteSchema = z.object({
  id: z.string(),
  title: z.string(),
  path: z.string(),
  content: z.string(),
});

function matches(note: KnowledgeBaseAssistantNote, query: string): boolean {
  const normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.length === 0) return true;
  return `${note.title}\n${note.path}\n${note.content}`
    .toLowerCase()
    .includes(normalizedQuery);
}

function summaryFor(note: KnowledgeBaseAssistantNote) {
  return {
    id: note.id,
    title: note.title,
    path: note.path,
    excerpt: limitedContent(note.content, 700),
  };
}

function noteForTool(note: KnowledgeBaseAssistantNote) {
  return {...note, content: limitedContent(note.content, 12000)};
}

function limitedContent(content: string, limit: number): string {
  if (content.length <= limit) return content;
  return `${content.slice(0, limit)}\n\n[Inhalt gekürzt]`;
}

async function teamIdForContext(
  context: unknown,
  teamContextStore: TeamContextStore,
): Promise<string> {
  return teamContextStore.currentTeamIdForUid(
    assistantActorIdFromContext(context),
  );
}
