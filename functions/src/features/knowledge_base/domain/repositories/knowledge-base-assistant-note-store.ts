import {type KnowledgeNote} from "../entities/knowledge-note.js";

export interface KnowledgeBaseAssistantNoteStore {
  /** Alle Notizen des Teams: Suche und Links brauchen den ganzen Zettelkasten. */
  listNotes(teamId: string): Promise<KnowledgeNote[]>;
}
