import {type MessageData, type ToolAction} from "genkit";
import {ResultAsync} from "neverthrow";
import {type TeamworkOutputField} from "../../../../domain/entities/teamwork-config.js";
import {type TeamworkExecutionRequest, type TeamworkExecutionResult} from "../../../../domain/entities/teamwork-execution.js";
import {type TeamworkExecutor} from "../../../../domain/executors/teamwork-executor.js";
import {type ApplicationLogger} from "../../../../../../shared/logging/application-logger.js";
import {type LanguageModelFailure} from "../../../../../language_models/domain/entities/language-model-failure.js";
import {type LlmGateway} from "../../../../../language_models/domain/prompting/llm-gateway.js";
import {type LlmPrompt} from "../../../../../language_models/domain/prompting/llm-prompt.js";
import {ModelOutputSchemaError} from "../../../../../language_models/infrastructure/errors/language-model-errors.js";
import {languageModelFailureFrom} from "../../../../../language_models/infrastructure/errors/language-model-failure-mapper.js";
import {type GenkitLlmBinding} from "../../../../../language_models/infrastructure/genkit/llm/genkit-llm-binding.js";
import {createLlmGateway} from "../../../../../language_models/infrastructure/genkit/llm/llm-gateway-factory.js";
import {type NodeAttachmentWorkspace} from "../../runner/node-attachment-workspace.js";
import {ReadableLlmCallLog} from "../../runner/readable-llm-call-log.js";
import {type TeamWorkspace} from "../../runner/teamwork-workspace.js";
import {delegationToolsFor} from "./teamwork-delegation-tools.js";
import {writeTeamworkImages} from "./teamwork-images.js";
import {teamworkMiddleware} from "./teamwork-middleware.js";
import {teamMemberRuns} from "./teamwork-member-runs.js";
import {teamworkModelFor, type TeamworkModel, type TeamworkModelSources} from "./teamwork-model.js";
import {teamworkResultFields} from "./teamwork-output-schema.js";
import {orchestratorPrompt, revisionPrompt} from "./teamwork-prompts.js";
import {reviewedResult} from "./teamwork-review.js";
import {reviewedFields, type OrchestrationRound} from "./teamwork-review-loop.js";
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

/** Der erste Turn bringt Systemteil und Aufgabe; eine Überarbeitung setzt das bisherige Gespräch fort. */
type OrchestratorTurn = {prompt: LlmPrompt; continuation?: MessageData[]; revision: number};

/**
 * Ein Orchestrator mit eigenem Modell vergibt Aufträge an die Mitarbeiter (je eigenes Modell, eigene
 * Fähigkeiten, ein Gespräch je Lauf) und liefert das strukturierte Endergebnis; ist die Prüfung an, prüft ein
 * eigenes Modell es vor der Abgabe. Alle Modellaufrufe laufen über das LLM-Framework; an dieser Grenze
 * werden Exceptions zur `LanguageModelFailure`.
 */
export class GenkitTeamworkExecutor implements TeamworkExecutor {
  private readonly gateway: LlmGateway<GenkitLlmBinding>;

  constructor(private readonly dependencies: GenkitTeamworkExecutorDependencies) {
    this.gateway = createLlmGateway(new ReadableLlmCallLog(dependencies.logger));
  }

  execute(request: TeamworkExecutionRequest): ResultAsync<TeamworkExecutionResult, LanguageModelFailure> {
    return ResultAsync.fromPromise(this.run(request), languageModelFailureFrom);
  }

  private async run(request: TeamworkExecutionRequest): Promise<TeamworkExecutionResult> {
    const {workspace, transcript} = this.dependencies;
    const orchestrator = await teamworkModelFor(request, this.dependencies, {label: "den Orchestrator", needsStructuredOutput: true});
    const reviewer = await this.reviewerFor(request);
    const runs = await teamMemberRuns(request, workspace, this.dependencies);
    const imagePaths = await writeTeamworkImages(workspace.rootDirectory, request.mediaUrls);
    const orchestration = {orchestrator, request, tools: delegationToolsFor(orchestrator.ai, runs, transcript)};
    const first = await this.orchestrate(orchestration, {revision: 0, prompt: orchestratorPrompt({
      members: runs, fields: request.outputFields, instruction: request.instruction, mediaUrls: request.mediaUrls,
      workspace, imagePaths,
    })});
    const fields = reviewer
      ? await reviewedFields(first, (result, round) => this.review(reviewer, request, result, round), transcript)
      : first.fields;
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
    return reviewedResult(reviewer, request, result, {rootDirectory: this.dependencies.workspace.rootDirectory, gateway: this.gateway, round});
  }

  /** Eine Runde des Orchestrators; eine Überarbeitung setzt sein bisheriges Gespräch fort. */
  private async orchestrate(orchestration: Orchestration, turn: OrchestratorTurn): Promise<OrchestrationRound> {
    const {orchestrator, request, tools} = orchestration;
    const response = await this.gateway.generate({
      binding: {
        ai: orchestrator.ai, model: orchestrator.model, config: orchestrator.config, logContext: orchestrator.logContext,
        tools, maxTurns: orchestratorMaxTurns, continuation: turn.continuation,
        use: teamworkMiddleware(this.dependencies.workspace.rootDirectory),
      },
      prompt: turn.prompt,
      label: turn.revision === 0 ? "Teamwork / Orchestrator" : `Teamwork / Orchestrator (Überarbeitung ${turn.revision})`,
      output: {kind: "structured", fields: teamworkResultFields(request.outputFields)},
    });
    if (!isRecord(response.data)) throw new ModelOutputSchemaError(`Das Team lieferte kein strukturiertes Ergebnis: ${response.text}`);
    return {
      fields: definedOutputOf(response.data, request.outputFields),
      revise: (findings) => this.orchestrate(orchestration, {
        prompt: revisionPrompt(findings), continuation: response.conversation as MessageData[], revision: turn.revision + 1,
      }),
    };
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function definedOutputOf(output: Record<string, unknown>, fields: TeamworkOutputField[]): Record<string, unknown> {
  return Object.fromEntries(fields.map((field) => field.name.trim()).filter((name) => name in output)
    .map((name) => [name, output[name]]));
}
