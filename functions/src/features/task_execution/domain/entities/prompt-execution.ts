import {
  type NodeOutputValue,
  type PromptOutputType,
  type ResolvedEmployee,
  type StructuredOutputField,
} from "./task.js";
import {type GenerationOptions} from "../../../language_models/domain/entities/generation-options.js";

export type PromptExecutionRequest = {
  teamId: string;
  instruction: string;
  languageModelId?: string;
  outputType: PromptOutputType;
  choices: string[];
  structuredFields: StructuredOutputField[];
  mediaUrls: string[];
  generationOptions: GenerationOptions;
  employee?: ResolvedEmployee;
};

export type PromptExecutionResult = {
  answer: string;
  outputs: Record<string, NodeOutputValue>;
};
