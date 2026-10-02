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

export type EmployeeAttachment = {
  employeeId: string;
  name: string;
  role: string;
  promptTemplate: string;
  defaultSkills: SkillAttachment[];
};
