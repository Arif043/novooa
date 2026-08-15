import {type AssistantCommand} from "../../../assistant/domain/entities/assistant-command.js";

export type TaskBuilderAssistantPrimitive =
  | "stringInput"
  | "prompt"
  | "readChannelEvent"
  | "sendChannelMessage"
  | "humanApproval"
  | "script";

export type TaskBuilderAssistantCommand = AssistantCommand & {
  type: "renameTask" | "addNode";
  primitive?: TaskBuilderAssistantPrimitive;
  kind?: "email" | "whatsapp" | "sms";
  title?: string;
  referenceName?: string;
  description?: string;
  value?: string;
  instruction?: string;
  recipient?: string;
  message?: string;
};

export type TaskBuilderAssistantResponse = {
  answer: string;
  commands: TaskBuilderAssistantCommand[];
  knowledgeCommands: AssistantCommand[];
};
