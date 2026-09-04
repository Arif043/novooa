import {
  type EmployeeAttachment,
  type NodeOutputValue,
  type PromptOutputType,
  type StructuredOutputField,
} from "../entities/task.js";

export type PromptExecutionRequest = {
  instruction: string;
  context: string;
  outputType: PromptOutputType;
  choices: string[];
  structuredFields: StructuredOutputField[];
  mediaUrls: string[];
  employee?: EmployeeAttachment;
};

export type PromptExecutionResult = {
  answer: string;
  outputs: Record<string, NodeOutputValue>;
};

export interface PromptExecutor {
  execute(request: PromptExecutionRequest): Promise<PromptExecutionResult>;
}
