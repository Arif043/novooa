import {type TeamworkExecutionRequest} from "../../../../domain/entities/teamwork-execution.js";
import {type ApplicationLogger} from "../../../../../../shared/logging/application-logger.js";
import {formatModelCallFinished, formatModelCallStarted} from "../../runner/structured-logger.js";
import {type TeamworkModel} from "./teamwork-model.js";

/** Rahmt den Lauf des Orchestrators im Protokoll; die Aufträge an Mitarbeiter stehen dazwischen. */
export async function loggedOrchestration<T>(
  logger: ApplicationLogger, orchestrator: TeamworkModel, request: TeamworkExecutionRequest, run: () => Promise<T>,
): Promise<T> {
  const label = "Teamwork / Orchestrator";
  const startedAt = Date.now();
  logger.readableInfo(formatModelCallStarted({
    label, model: orchestrator.logContext, prompt: request.instruction,
    outputSchema: request.outputFields.map((field) => field.name.trim()).join(", "),
    mediaCount: request.mediaUrls.length, options: orchestrator.config,
  }));
  const output = await run();
  logger.readableInfo(formatModelCallFinished({label, durationMs: Date.now() - startedAt, text: "", output}));
  return output;
}
