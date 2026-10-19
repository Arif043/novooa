import {type MessageData, type ToolAction} from "genkit";
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
import {orchestratorSystemPrompt} from "./teamwork-prompts.js";
import {reviewedResult} from "./teamwork-review.js";
import {reviewedFields, type OrchestrationRound} from "./teamwork-review-loop.js";
import {revisionPrompt} from "./teamwork-review-prompts.js";
import {type TeamworkTranscript} from "./teamwork-transcript.js";

/** Der Orchestrator darf je Runde so viele Schritte machen: Aufträge, Antworten lesen, Dateien prüfen, Ergebnis. */
const orchestratorMaxTurns = 12;

export type GenkitTeamworkExecutorDependencies = TeamworkModelSources & {
  workspace: NodeAttachmentWorkspace & {team: TeamWorkspace};
  logger: ApplicationLogger;
  /** Sammelt das Gespräch; der Aufrufer liest es auch, wenn der Lauf scheitert. */
  transcript: TeamworkTranscript;
};

type Orchestration = {orchestrator: TeamworkModel; request: TeamworkExecutionRequest; tools: ToolAction[]};

/** Der erste Turn bekommt Rolle und Aufgabe; eine Überarbeitung setzt das bisherige Gespräch fort. */
type OrchestratorTurn =
  | {system: string; prompt: ReturnType<typeof promptFor>}
  | {messages: MessageData[]; prompt: string};

/**
 * Ein Orchestrator mit eigenem Modell vergibt Aufträge an die Mitarbeiter (je eigenes Modell, eigene
 * Fähigkeiten, ein Gespräch je Lauf) und liefert das strukturierte Endergebnis; ist die Prüfung an, prüft ein
 * eigenes Modell es vor der Abgabe. An dieser Grenze werden Exceptions zur `LanguageModelFailure`.
 */
export class GenkitTeamworkExecutor implements TeamworkExecutor {
  constructor(private readonly dependencies: GenkitTeamworkExecutorDependencies) {}

  execute(request: TeamworkExecutionRequest): ResultAsync<TeamworkExecutionResult, LanguageModelFailure> {
    return ResultAsync.fromPromise(this.run(request), languageModelFailureFrom);
  }

  private async run(request: TeamworkExecutionRequest): Promise<TeamworkExecutionResult> {
    const {workspace, logger, transcript} = this.dependencies;
    const orchestrator = await teamworkModelFor(request, this.dependencies, {label: "den Orchestrator", needsStructuredOutput: true});
    const reviewer = await this.reviewerFor(request);
    const runs = await teamMemberRuns(request, workspace, this.dependencies);
    const orchestration = {orchestrator, request, tools: delegationToolsFor(orchestrator.ai, runs, transcript)};
    const fields = await loggedOrchestration(logger, orchestrator, request, async () => {
      const first = await this.orchestrate(orchestration, {
        system: orchestratorSystemPrompt(runs, request.outputFields), prompt: promptFor(request),
      });
      return reviewer ? reviewedFields(first, (result, round) => this.review(reviewer, request, result, round), transcript) : first.fields;
    });
    transcript.result(fields);
    return {answer: JSON.stringify(fields), fields};
  }

  private async reviewerFor(request: TeamworkExecutionRequest): Promise<TeamworkModel | undefined> {
    if (!request.review.enabled) return undefined;
    return teamworkModelFor(
      {languageModelId: request.review.languageModelId, teamId: request.teamId, generationOptions: request.generationOptions},
      this.dependencies,
      {label: "die Prüfung", needsStructuredOutput: true},
    );
  }

  private review(reviewer: TeamworkModel, request: TeamworkExecutionRequest, result: Record<string, unknown>, round: number) {
    const {workspace, logger} = this.dependencies;
    return reviewedResult(reviewer, request, result, {rootDirectory: workspace.rootDirectory, logger, round});
  }

  /** Eine Runde des Orchestrators; eine Überarbeitung setzt sein bisheriges Gespräch fort. */
  private async orchestrate(orchestration: Orchestration, turn: OrchestratorTurn): Promise<OrchestrationRound> {
    const {orchestrator, request, tools} = orchestration;
    const response = await withTranslatedGenkitErrors(() => orchestrator.ai.generate({
      model: orchestrator.model, config: orchestrator.config, maxTurns: orchestratorMaxTurns,
      ...turn,
      tools,
      use: teamworkMiddleware(this.dependencies.workspace.rootDirectory),
      output: {schema: teamworkSchemaFor(request.outputFields)},
    }));
    const output = response.output;
    if (!output) throw new ModelOutputSchemaError(`Das Team lieferte kein strukturiertes Ergebnis: ${response.text}`);
    return {
      fields: definedOutputOf(output, request.outputFields),
      revise: (findings) => this.orchestrate(orchestration, {messages: response.messages, prompt: revisionPrompt(findings)}),
    };
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
