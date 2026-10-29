import {and, eq, sql} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {knowledgeNotes, type KnowledgeNotes} from "../../../../db/schema.js";
import {type KnowledgeNote} from "../../domain/entities/knowledge-note.js";
import {type KnowledgeBaseAssistantNoteStore} from "../../domain/repositories/knowledge-base-assistant-note-store.js";

type KnowledgeNoteRow = Pick<KnowledgeNotes, "id" | "title" | "path" | "content">;

export class SQLiteKnowledgeBaseAssistantNoteStore
  implements KnowledgeBaseAssistantNoteStore {
  constructor(private readonly database: RuntimeExecutor) {}

  async listNotes(teamId: string): Promise<KnowledgeNote[]> {
    const rows = await this.database.select({id: knowledgeNotes.id, title: knowledgeNotes.title, path: knowledgeNotes.path, content: knowledgeNotes.content}).from(knowledgeNotes).where(and(eq(knowledgeNotes.team_id, teamId), eq(knowledgeNotes.knowledge_base_id, defaultKnowledgeBaseId))).orderBy(sql`${knowledgeNotes.title} COLLATE NOCASE`, knowledgeNotes.id);
    return rows.map(noteFromRow);
  }
}

const defaultKnowledgeBaseId = "default";

function noteFromRow(row: KnowledgeNoteRow): KnowledgeNote {
  return {id: row.id, title: row.title, path: row.path, content: row.content};
}
