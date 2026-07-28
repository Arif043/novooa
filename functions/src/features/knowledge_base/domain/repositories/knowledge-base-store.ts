import {type KnowledgeAttachment} from "../../../task_execution/domain/entities/attachments.js";

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
