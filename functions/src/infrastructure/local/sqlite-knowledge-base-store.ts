import {type KnowledgeAttachment} from "../../domain/entities/attachments.js";
import {
  type KnowledgeBaseStore,
  type KnowledgeNoteDocument,
} from "../../domain/repositories/knowledge-base-store.js";
import {type LocalSqlDatabase, type SqlRow} from "./local-sql-database.js";

type KnowledgeNoteRow = SqlRow & {
  id: string;
  title: string;
  path: string;
  type: string;
  content: string;
  outgoing_links_json: string;
};

export class SQLiteKnowledgeBaseStore implements KnowledgeBaseStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  async loadNote(
    teamId: string,
    attachment: KnowledgeAttachment,
  ): Promise<KnowledgeNoteDocument> {
    const noteOrNull = await this.database.get<KnowledgeNoteRow>(
      `SELECT id, title, path, type, content, outgoing_links_json
       FROM knowledge_notes
       WHERE team_id = ? AND knowledge_base_id = ? AND id = ?`,
      [teamId, attachment.knowledgeBaseId, attachment.noteId],
    );
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
    type: noteTypeFrom(row.type, attachment.type),
    content: row.content,
    outgoingLinks: stringListFrom(row.outgoing_links_json),
  };
}

function noteTypeFrom(value: string, fallback: KnowledgeAttachment["type"]) {
  if (value === "atomic" || value === "moc" || value === "unknown") return value;
  return fallback;
}

function stringListFrom(value: string): string[] {
  const parsed: unknown = JSON.parse(value);
  if (!Array.isArray(parsed)) return [];
  return parsed.filter((item): item is string => typeof item === "string");
}
