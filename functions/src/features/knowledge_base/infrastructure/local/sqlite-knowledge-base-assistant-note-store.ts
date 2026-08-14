import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";
import {
  type KnowledgeBaseAssistantNote,
  type KnowledgeBaseAssistantNoteStore,
} from "../../domain/repositories/knowledge-base-assistant-note-store.js";

type KnowledgeNoteRow = SqlRow & {
  id: string;
  title: string;
  path: string;
  content: string;
};

export class SQLiteKnowledgeBaseAssistantNoteStore
  implements KnowledgeBaseAssistantNoteStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  async listNotes(teamId: string): Promise<KnowledgeBaseAssistantNote[]> {
    const rows = await this.database.all<KnowledgeNoteRow>(
      listNotesSql,
      [teamId, defaultKnowledgeBaseId, maximumNotes],
    );
    return rows.map(noteFromRow);
  }

  async findNote(
    teamId: string,
    noteId: string,
  ): Promise<KnowledgeBaseAssistantNote | null> {
    const row = await this.database.get<KnowledgeNoteRow>(
      findNoteSql,
      [teamId, defaultKnowledgeBaseId, noteId],
    );
    return row && noteFromRow(row);
  }
}

const defaultKnowledgeBaseId = "default";
const maximumNotes = 50;

const listNotesSql = `SELECT id, title, path, content
  FROM knowledge_notes
  WHERE team_id = ? AND knowledge_base_id = ?
  ORDER BY title COLLATE NOCASE, id
  LIMIT ?`;

const findNoteSql = `SELECT id, title, path, content
  FROM knowledge_notes
  WHERE team_id = ? AND knowledge_base_id = ? AND id = ?`;

function noteFromRow(row: KnowledgeNoteRow): KnowledgeBaseAssistantNote {
  return {id: row.id, title: row.title, path: row.path, content: row.content};
}
