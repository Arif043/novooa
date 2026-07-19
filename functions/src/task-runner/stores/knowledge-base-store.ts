import {type KnowledgeAttachment} from "../task-definition.js";

export type KnowledgeNoteDocument = KnowledgeAttachment & {
  content: string;
  outgoingLinks: string[];
};

export interface KnowledgeBaseStore {
  loadNote(
    teamId: string,
    attachment: KnowledgeAttachment,
  ): Promise<KnowledgeNoteDocument>;
}
