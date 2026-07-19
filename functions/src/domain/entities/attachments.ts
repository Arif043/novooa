export type KnowledgeNoteType = "atomic" | "moc" | "unknown";

export type NodeAttachment = {
  id: string;
  storagePath: string;
  generation: string;
  displayName: string;
  contentType: string;
  sizeBytes: number;
};

export type KnowledgeAttachment = {
  knowledgeBaseId: string;
  noteId: string;
  title: string;
  path: string;
  type: KnowledgeNoteType;
};

export type SkillAttachment = {
  skillId: string;
  title: string;
  description: string;
  storagePath: string;
};

export type EmployeeAttachment = {
  employeeId: string;
  name: string;
  role: string;
  promptTemplate: string;
  defaultSkills: SkillAttachment[];
};
