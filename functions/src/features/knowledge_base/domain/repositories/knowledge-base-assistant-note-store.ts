export type KnowledgeBaseAssistantNote = {
  id: string;
  title: string;
  path: string;
  content: string;
};

export interface KnowledgeBaseAssistantNoteStore {
  listNotes(teamId: string): Promise<KnowledgeBaseAssistantNote[]>;

  findNote(
    teamId: string,
    noteId: string,
  ): Promise<KnowledgeBaseAssistantNote | null>;
}
