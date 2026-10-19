import {type ResultAsync} from "neverthrow";
import {type TeamworkExecutionRequest, type TeamworkExecutionResult} from "../entities/teamwork-execution.js";
import {type LanguageModelFailure} from "../../../language_models/domain/entities/language-model-failure.js";

/** Lässt einen Orchestrator mit seinen Mitarbeitern arbeiten; Fehler der Modellaufrufe kommen als Failure zurück. */
export interface TeamworkExecutor {
  execute(request: TeamworkExecutionRequest): ResultAsync<TeamworkExecutionResult, LanguageModelFailure>;
}
