import {
  type NodeOutputValue,
  type PromptOutputType,
  type ResolvedEmployee,
  type StructuredOutputField,
} from "./task.js";

export type PromptExecutionRequest = {
  instruction: string;
  context: string;
  languageModelId?: string;
  outputType: PromptOutputType;
  choices: string[];
  structuredFields: StructuredOutputField[];
  mediaUrls: string[];
  employee?: ResolvedEmployee;
};

export type PromptExecutionResult = {
  answer: string;
  outputs: Record<string, NodeOutputValue>;
};
