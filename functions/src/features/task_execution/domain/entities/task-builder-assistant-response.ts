import {type AssistantCommand} from "../../../assistant/domain/entities/assistant-command.js";

/** Bausteine, die der KI-Agent per addNode vorschlagen darf. */
export const taskBuilderAssistantPrimitives = [
  "stringInput",
  "prompt",
  "readChannelEvent",
  "sendChannelMessage",
  "humanApproval",
  "dialogInput",
  "mediaInput",
  "modelInference",
  "script",
] as const;

export type TaskBuilderAssistantPrimitive = typeof taskBuilderAssistantPrimitives[number];

export type TaskBuilderAssistantCommand = AssistantCommand & {
  type: "renameTask" | "addNode";
  primitive?: TaskBuilderAssistantPrimitive;
  kind?: "email" | "whatsapp" | "sms";
  title?: string;
  outputName?: string;
  description?: string;
  value?: string;
  instruction?: string;
  modelId?: string;
  recipient?: string;
  message?: string;
  script?: string;
  inputTemplate?: string;
};

export type TaskBuilderAssistantResponse = {
  answer: string;
  commands: TaskBuilderAssistantCommand[];
  knowledgeCommands: AssistantCommand[];
};
