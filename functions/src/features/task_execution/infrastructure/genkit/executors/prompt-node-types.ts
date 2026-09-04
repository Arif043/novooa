import {
  type PromptExecutionRequest,
  type PromptExecutionResult,
} from "../../../domain/repositories/prompt-executor.js";

export type PromptNodeInput = PromptExecutionRequest;
export type PromptNodeOutput = PromptExecutionResult;
export type PromptNodeOutputType = PromptNodeInput["outputType"];
export type StructuredOutputField = PromptNodeInput["structuredFields"][number];

export type PromptContent = {
  text: string;
  content: string | Array<{text: string} | {media: {url: string}}>;
};
