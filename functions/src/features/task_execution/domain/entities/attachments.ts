export type NodeAttachment = {
  id: string;
  storagePath: string;
  generation: string;
  displayName: string;
  contentType: string;
  sizeBytes: number;
  versionCreatedAt?: number;
};

export type KnowledgeAttachment = {
  knowledgeBaseId: string;
  noteId: string;
  title: string;
  path: string;
};

/** Verweis auf einen Skill im Skills-Ordner; `name` ist der Ordnername, `description` nur zur Anzeige. */
export type SkillAttachment = {
  name: string;
  description: string;
};

/** Der Mitarbeiter eines Bausteins, beim Lauf aus dem Speicher geladen: `constraint` ist der System-Prompt. */
export type ResolvedEmployee = {
  id: string;
  name: string;
  constraint: string;
};
