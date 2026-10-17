import {type ResultAsync} from "neverthrow";
import {type PromptExecutionRequest, type PromptExecutionResult} from "../entities/prompt-execution.js";
import {type LanguageModelFailure} from "../../../language_models/domain/entities/language-model-failure.js";

/** Führt einen Prompt mit einem Sprachmodell aus; Fehler des Modellaufrufs kommen als Failure zurück. */
export interface PromptExecutor {
  execute(request: PromptExecutionRequest): ResultAsync<PromptExecutionResult, LanguageModelFailure>;
}
