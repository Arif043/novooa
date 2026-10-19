import {type ToolAction} from "genkit";
import {ResultAsync} from "neverthrow";
import {type TeamworkOutputField} from "../../../../domain/entities/teamwork-config.js";
import {type TeamworkExecutionRequest, type TeamworkExecutionResult} from "../../../../domain/entities/teamwork-execution.js";
import {type TeamworkExecutor} from "../../../../domain/executors/teamwork-executor.js";
import {type ApplicationLogger} from "../../../../../../shared/logging/application-logger.js";
import {type LanguageModelFailure} from "../../../../../language_models/domain/entities/language-model-failure.js";
import {withTranslatedGenkitErrors} from "../../../../../language_models/infrastructure/errors/genkit-error-translator.js";
import {ModelOutputSchemaError} from "../../../../../language_models/infrastructure/errors/language-model-errors.js";
import {languageModelFailureFrom} from "../../../../../language_models/infrastructure/errors/language-model-failure-mapper.js";
import {type NodeAttachmentWorkspace} from "../../runner/node-attachment-workspace.js";
import {type TeamWorkspace} from "../../runner/teamwork-workspace.js";
import {loggedOrchestration} from "./teamwork-orchestration-log.js";
import {delegationToolsFor} from "./teamwork-delegation-tools.js";
import {teamworkMiddleware} from "./teamwork-middleware.js";
import {teamMemberRuns} from "./teamwork-member-runs.js";
import {teamworkModelFor, type TeamworkModel, type TeamworkModelSources} from "./teamwork-model.js";
import {teamworkSchemaFor} from "./teamwork-output-schema.js";
import {orchestratorSystemPrompt, type TeamMemberTool} from "./teamwork-prompts.js";

/** Der Orchestrator darf so viele Runden drehen: Aufträge, Antworten lesen, Dateien prüfen, Ergebnis. */
const orchestratorMaxTurns = 12;

export type GenkitTeamworkExecutorDependencies = TeamworkModelSources & {
  workspace: NodeAttachmentWorkspace & {team: TeamWorkspace};
  logger: ApplicationLogger;
};

/**
 * Ein Orchestrator mit eigenem Modell vergibt Aufträge an die Mitarbeiter (je eigenes Modell und eigene
 * Fähigkeiten) und liefert das strukturierte Endergebnis. An dieser Grenze werden Exceptions zur
 * `LanguageModelFailure`.
 */
export class GenkitTeamworkExecutor implements TeamworkExecutor {
  constructor(private readonly dependencies: GenkitTeamworkExecutorDependencies) {}

  execute(request: TeamworkExecutionRequest): ResultAsync<TeamworkExecutionResult, LanguageModelFailure> {
    return ResultAsync.fromPromise(this.run(request), languageModelFailureFrom);
  }

  private async run(request: TeamworkExecutionRequest): Promise<TeamworkExecutionResult> {
    const {workspace, logger} = this.dependencies;
    const orchestrator = await teamworkModelFor(request, this.dependencies, {label: "den Orchestrator", needsStructuredOutput: true});
    const runs = await teamMemberRuns(request, workspace, this.dependencies);
    const tools = delegationToolsFor(orchestrator.ai, runs, logger);
    const fields = await loggedOrchestration(logger, orchestrator, request, () => this.orchestrate(orchestrator, request, runs, tools));
    return {answer: JSON.stringify(fields), fields};
  }

  private async orchestrate(
    orchestrator: TeamworkModel, request: TeamworkExecutionRequest, members: TeamMemberTool[], tools: ToolAction[],
  ): Promise<Record<string, unknown>> {
    const response = await withTranslatedGenkitErrors(() => orchestrator.ai.generate({
      model: orchestrator.model, config: orchestrator.config, maxTurns: orchestratorMaxTurns,
      system: orchestratorSystemPrompt(members, request.outputFields),
      prompt: promptFor(request), tools,
      use: teamworkMiddleware(this.dependencies.workspace.rootDirectory),
      output: {schema: teamworkSchemaFor(request.outputFields)},
    }));
    const output = response.output;
    if (!output) throw new ModelOutputSchemaError(`Das Team lieferte kein strukturiertes Ergebnis: ${response.text}`);
    return definedOutputOf(output, request.outputFields);
  }
}

function promptFor(request: TeamworkExecutionRequest) {
  if (request.mediaUrls.length === 0) return request.instruction;
  return [{text: request.instruction}, ...request.mediaUrls.map((url) => ({media: {url}}))];
}

function definedOutputOf(output: Record<string, unknown>, fields: TeamworkOutputField[]): Record<string, unknown> {
  return Object.fromEntries(fields.map((field) => field.name.trim()).filter((name) => name in output)
    .map((name) => [name, output[name]]));
}
