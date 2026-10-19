import {filesystem} from "@genkit-ai/middleware";
import {z} from "genkit";
import {type TeamworkExecutionRequest} from "../../../../domain/entities/teamwork-execution.js";
import {type ApplicationLogger} from "../../../../../../shared/logging/application-logger.js";
import {withTranslatedGenkitErrors} from "../../../../../language_models/infrastructure/errors/genkit-error-translator.js";
import {ModelOutputSchemaError} from "../../../../../language_models/infrastructure/errors/language-model-errors.js";
import {languageModelRetry} from "../../../../../language_models/infrastructure/genkit/language-model-retry.js";
import {formatModelCallFinished, formatModelCallStarted} from "../../runner/structured-logger.js";
import {type TeamworkModel} from "./teamwork-model.js";
import {reviewerSystemPrompt, reviewPrompt} from "./teamwork-review-prompts.js";

/** Das Urteil der Prüfung. */
export type TeamworkVerdict = {approved: boolean; findings: string};

const verdictSchema = z.object({
  approved: z.coerce.boolean().describe("true, wenn das Ergebnis ohne Mängel abgegeben werden kann."),
  findings: z.string().describe("Die Mängel, konkret und behebbar; leer, wenn freigegeben."),
});

/** Die Prüfung liest den Arbeitsordner nur; sie bessert nicht selbst nach. */
const reviewerMaxTurns = 8;

/** Prüft ein Ergebnis mit dem Modell der Prüfung und protokolliert den Aufruf. */
export async function reviewedResult(
  reviewer: TeamworkModel, request: TeamworkExecutionRequest, result: Record<string, unknown>,
  context: {rootDirectory: string; logger: ApplicationLogger; round: number},
): Promise<TeamworkVerdict> {
  const label = `Teamwork / Prüfung ${context.round}`;
  const prompt = reviewPrompt(request.instruction, request.outputFields, result);
  const startedAt = Date.now();
  context.logger.readableInfo(formatModelCallStarted({
    label, model: reviewer.logContext, prompt, outputSchema: "approved, findings", mediaCount: 0, options: reviewer.config,
  }));
  const verdict = await verdictOf(reviewer, prompt, context.rootDirectory);
  context.logger.readableInfo(formatModelCallFinished({label, durationMs: Date.now() - startedAt, text: "", output: verdict}));
  return verdict;
}

async function verdictOf(reviewer: TeamworkModel, prompt: string, rootDirectory: string): Promise<TeamworkVerdict> {
  const response = await withTranslatedGenkitErrors(() => reviewer.ai.generate({
    model: reviewer.model, config: reviewer.config, maxTurns: reviewerMaxTurns,
    system: reviewerSystemPrompt(), prompt,
    use: [languageModelRetry(), filesystem({rootDirectory, allowWriteAccess: false})],
    output: {schema: verdictSchema},
  }));
  if (!response.output) throw new ModelOutputSchemaError(`Die Prüfung lieferte kein Urteil: ${response.text}`);
  return response.output;
}
