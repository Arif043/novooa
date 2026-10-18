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

/** Felder, die configureNode in einem Baustein befüllen darf. */
export const taskBuilderAssistantFieldKeys = [
  "title",
  "description",
  "outputName",
  "value",
  "instruction",
  "modelId",
  "recipient",
  "message",
  "script",
] as const;

export type TaskBuilderAssistantPrimitive = typeof taskBuilderAssistantPrimitives[number];

export type TaskBuilderAssistantCommand = AssistantCommand & {
  type: "renameTask" | "addNode" | "configureNode";
  /** Plan-lokale Kennung eines addNode-Commands, auf die configureNode zeigt. */
  ref?: string;
  nodeRef?: string;
  fields?: Record<string, string>;
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
};

export type TaskBuilderAssistantResponse = {
  answer: string;
  commands: TaskBuilderAssistantCommand[];
  knowledgeCommands: AssistantCommand[];
};
