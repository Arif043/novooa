import {filesystem} from "@genkit-ai/middleware";
import {type TeamworkExecutionRequest} from "../../../../domain/entities/teamwork-execution.js";
import {type LlmGateway} from "../../../../../language_models/domain/prompting/llm-gateway.js";
import {ModelOutputSchemaError} from "../../../../../language_models/infrastructure/errors/language-model-errors.js";
import {languageModelRetry} from "../../../../../language_models/infrastructure/genkit/language-model-retry.js";
import {type GenkitLlmBinding} from "../../../../../language_models/infrastructure/genkit/llm/genkit-llm-binding.js";
import {type TeamworkModel} from "./teamwork-model.js";
import {reviewPrompt, verdictFields} from "./teamwork-review-prompts.js";

/** Das Urteil der Prüfung. */
export type TeamworkVerdict = {approved: boolean; findings: string};

/** Die Prüfung liest den Arbeitsordner nur; sie bessert nicht selbst nach. */
const reviewerMaxTurns = 8;

/** Prüft ein Ergebnis mit dem Modell der Prüfung; das Protokoll schreibt der Gateway. */
export async function reviewedResult(
  reviewer: TeamworkModel, request: TeamworkExecutionRequest, result: Record<string, unknown>,
  context: {rootDirectory: string; gateway: LlmGateway<GenkitLlmBinding>; round: number},
): Promise<TeamworkVerdict> {
  const response = await context.gateway.generate({
    binding: {
      ai: reviewer.ai, model: reviewer.model, config: reviewer.config, logContext: reviewer.logContext,
      maxTurns: reviewerMaxTurns,
      use: [languageModelRetry(), filesystem({rootDirectory: context.rootDirectory, allowWriteAccess: false})],
    },
    prompt: reviewPrompt(request.instruction, request.outputFields, result),
    label: `Teamwork / Prüfung ${context.round}`,
    output: {kind: "structured", fields: verdictFields},
  });
  return verdictOf(response.data, response.text);
}

function verdictOf(data: unknown, text: string): TeamworkVerdict {
  const verdict = data as Partial<TeamworkVerdict> | undefined;
  if (typeof verdict?.approved !== "boolean") throw new ModelOutputSchemaError(`Die Prüfung lieferte kein Urteil: ${text}`);
  return {approved: verdict.approved, findings: typeof verdict.findings === "string" ? verdict.findings : ""};
}
