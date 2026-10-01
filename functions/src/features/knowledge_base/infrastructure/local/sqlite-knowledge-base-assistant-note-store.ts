import {and, eq, sql} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {knowledgeNotes, type KnowledgeNotes} from "../../../../db/schema.js";
import {
  type KnowledgeBaseAssistantNote,
  type KnowledgeBaseAssistantNoteStore,
} from "../../domain/repositories/knowledge-base-assistant-note-store.js";

type KnowledgeNoteRow = Pick<KnowledgeNotes, "id" | "title" | "path" | "content">;

export class SQLiteKnowledgeBaseAssistantNoteStore
  implements KnowledgeBaseAssistantNoteStore {
  constructor(private readonly database: RuntimeExecutor) {}

  async listNotes(teamId: string): Promise<KnowledgeBaseAssistantNote[]> {
    const rows = await this.database.select({id: knowledgeNotes.id, title: knowledgeNotes.title, path: knowledgeNotes.path, content: knowledgeNotes.content}).from(knowledgeNotes).where(and(eq(knowledgeNotes.team_id, teamId), eq(knowledgeNotes.knowledge_base_id, defaultKnowledgeBaseId))).orderBy(sql`${knowledgeNotes.title} COLLATE NOCASE`, knowledgeNotes.id).limit(maximumNotes);
    return rows.map(noteFromRow);
  }

  async findNote(
    teamId: string,
    noteId: string,
  ): Promise<KnowledgeBaseAssistantNote | null> {
    const row = (await this.database.select({id: knowledgeNotes.id, title: knowledgeNotes.title, path: knowledgeNotes.path, content: knowledgeNotes.content}).from(knowledgeNotes).where(and(eq(knowledgeNotes.team_id, teamId), eq(knowledgeNotes.knowledge_base_id, defaultKnowledgeBaseId), eq(knowledgeNotes.id, noteId))).get()) ?? null;
    return row && noteFromRow(row);
  }
}

const defaultKnowledgeBaseId = "default";
const maximumNotes = 50;

function noteFromRow(row: KnowledgeNoteRow): KnowledgeBaseAssistantNote {
  return {id: row.id, title: row.title, path: row.path, content: row.content};
}
