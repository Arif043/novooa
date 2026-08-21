import {type EmployeeAttachment, type NodeOutputValue} from "../runner/task-definition.js";

export type PromptNodeOutputType = "text" | "decision" | "structured" | "image";

export type StructuredOutputField = {
  name: string;
  description: string;
};

export type PromptNodeInput = {
  instruction: string;
  context: string;
  outputType: PromptNodeOutputType;
  choices: string[];
  structuredFields: StructuredOutputField[];
  mediaUrls: string[];
  employee?: EmployeeAttachment;
};

export type PromptNodeOutput = {
  answer: string;
  outputs: Record<string, NodeOutputValue>;
};

export type PromptContent = {
  text: string;
  content: string | Array<{text: string} | {media: {url: string}}>;
};
