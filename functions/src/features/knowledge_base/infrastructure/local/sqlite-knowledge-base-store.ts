import {type RuntimeExecutor} from "../../../../db/database.js";
import {type KnowledgeNotes} from "../../../../db/schema.js";
import {knowledgeNoteWithLinks} from "./sqlite-knowledge-link-projection.js";
import {type KnowledgeAttachment} from "../../../task_execution/domain/entities/attachments.js";
import {
  type KnowledgeBaseStore,
  type KnowledgeNoteDocument,
} from "../../domain/repositories/knowledge-base-store.js";

type KnowledgeNoteRow = Pick<KnowledgeNotes, "id" | "title" | "path" | "content"> & {outgoingLinks: string[]};

export class SQLiteKnowledgeBaseStore implements KnowledgeBaseStore {
  constructor(private readonly database: RuntimeExecutor) {}

  async loadNote(
    teamId: string,
    attachment: KnowledgeAttachment,
  ): Promise<KnowledgeNoteDocument> {
    const noteOrNull = await knowledgeNoteWithLinks(this.database, teamId, attachment.knowledgeBaseId, attachment.noteId);
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
    outgoingLinks: row.outgoingLinks,
  };
}
