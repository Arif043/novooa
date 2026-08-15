import {type AssistantCommand} from "../../../assistant/domain/entities/assistant-command.js";

export type KnowledgeBaseAssistantCommandType =
  | "createKnowledgeNote"
  | "updateKnowledgeNote"
  | "deleteKnowledgeNote";

export type KnowledgeBaseAssistantCommand = AssistantCommand & {
  type: KnowledgeBaseAssistantCommandType;
  noteId?: string;
  title?: string;
  content?: string;
};

export type KnowledgeBaseAssistantResponse = {
  answer: string;
  commands: AssistantCommand[];
  knowledgeCommands: KnowledgeBaseAssistantCommand[];
};
