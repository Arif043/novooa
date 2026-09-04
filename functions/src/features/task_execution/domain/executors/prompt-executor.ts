import {type PromptExecutionRequest, type PromptExecutionResult} from "../entities/prompt-execution.js";

export interface PromptExecutor {
  execute(request: PromptExecutionRequest): Promise<PromptExecutionResult>;
}
