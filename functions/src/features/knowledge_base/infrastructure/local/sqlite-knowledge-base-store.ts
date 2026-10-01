import {and, eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {knowledgeNotes, type KnowledgeNotes} from "../../../../db/schema.js";
import {type KnowledgeAttachment} from "../../../task_execution/domain/entities/attachments.js";
import {
  type KnowledgeBaseStore,
  type KnowledgeNoteDocument,
} from "../../domain/repositories/knowledge-base-store.js";

type KnowledgeNoteRow = Pick<KnowledgeNotes, "id" | "title" | "path" | "content" | "outgoing_links_json">;

export class SQLiteKnowledgeBaseStore implements KnowledgeBaseStore {
  constructor(private readonly database: RuntimeExecutor) {}

  async loadNote(
    teamId: string,
    attachment: KnowledgeAttachment,
  ): Promise<KnowledgeNoteDocument> {
    const noteOrNull = (await this.database.select({id: knowledgeNotes.id, title: knowledgeNotes.title, path: knowledgeNotes.path, content: knowledgeNotes.content, outgoing_links_json: knowledgeNotes.outgoing_links_json}).from(knowledgeNotes).where(and(eq(knowledgeNotes.team_id, teamId), eq(knowledgeNotes.knowledge_base_id, attachment.knowledgeBaseId), eq(knowledgeNotes.id, attachment.noteId))).get()) ?? null;
    if (noteOrNull === null) throw new Error(`Wissensnotiz fehlt: ${attachment.noteId}`);
    return noteFromRow(attachment, noteOrNull);
  }
}

function noteFromRow(
  attachment: KnowledgeAttachment,
  row: KnowledgeNoteRow,
): KnowledgeNoteDocument {
  return {
    knowledgeBaseId: attachment.knowledgeBaseId,
    noteId: row.id,
    title: row.title || attachment.title,
    path: row.path || attachment.path,
    content: row.content,
    outgoingLinks: stringListFrom(row.outgoing_links_json),
  };
}

function stringListFrom(value: string): string[] {
  const parsed: unknown = JSON.parse(value);
  if (!Array.isArray(parsed)) return [];
  return parsed.filter((item): item is string => typeof item === "string");
}
