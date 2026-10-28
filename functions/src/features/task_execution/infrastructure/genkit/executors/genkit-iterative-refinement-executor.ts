import {ok} from "neverthrow";
import {type GenkitBeta} from "genkit/beta";
import {type IterativeRefinementExecutor} from "../../../domain/executors/iterative-refinement-executor.js";
import {
  type IterativeRefinementRequest,
  type IterativeRefinementResult,
} from "../../../domain/entities/iterative-refinement-execution.js";
import {type NodeExecutor, executedNode, textOutputs} from "../../../domain/executors/node-executor.js";
import {createLlmGateway} from "../../../../language_models/infrastructure/genkit/llm/llm-gateway-factory.js";
import {refinementConfigFor} from "./iterative-refinement-config.js";
import {type Evaluation} from "./iterative-refinement-evaluation.js";
import {
  formatEvaluation,
  formatImprovement,
  formatRefinementFinished,
  formatRefinementStarted,
} from "./iterative-refinement-format.js";
import {improvement, type RefinementCall, structuredEvaluation, textEvaluation} from "./iterative-refinement-calls.js";
import {formatException} from "../runner/structured-logger.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {ReadableLlmCallLog} from "../runner/readable-llm-call-log.js";
import {errorDetails, type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";
import {FirebaseApplicationLogger} from "../../../../../shared/logging/firebase-application-logger.js";

export type IterativeRefinementNodeInput = IterativeRefinementRequest;
export type IterativeRefinementNodeOutput = IterativeRefinementResult;

export function createGenkitIterativeRefinementNodeExecutor(
  ai: GenkitBeta,
  workspace?: NodeAttachmentWorkspace,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
): NodeExecutor {
  return {
    primitive: "iterativeRefinement",
    async execute(node, runContext) {
      const config = refinementConfigFor(node);
      const draft = config?.draftTemplate ?? "";
      const employee = workspace?.employee;
      const output = await createGenkitIterativeRefinementExecutor(
        ai,
        workspace,
        logger,
      ).execute({
        objective: runContext.templateExpressionResolver.resolveText(runContext.rootTask.objective),
        draft: runContext.templateExpressionResolver.resolveText(draft),
        optimizerPrompt: runContext.templateExpressionResolver.resolveText(config?.optimizerPrompt ||
          node.description ||
          node.title),
        critiquePrompt: runContext.templateExpressionResolver.resolveText(config?.critiquePrompt ||
          node.description ||
          node.title),
        maxIterations: config?.maxIterations ?? 2,
        employee,
      });
      return ok(executedNode(node, textOutputs(output.answer)));
    },
  };
}

export async function executeIterativeRefinementNode(
  ai: GenkitBeta,
  input: IterativeRefinementNodeInput,
  attachmentWorkspace?: NodeAttachmentWorkspace,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
): Promise<IterativeRefinementNodeOutput> {
  const call: RefinementCall = {ai, workspace: attachmentWorkspace, gateway: createLlmGateway(new ReadableLlmCallLog(logger))};
  const maxIterations = boundedIterations(input.maxIterations);
  let answer = input.draft;
  let iterations = 0;
  logger.readableInfo(formatRefinementStarted(input, maxIterations));
  for (let nextIteration = 1; nextIteration <= maxIterations; nextIteration += 1) {
    iterations = nextIteration;
    const evaluation = await evaluateDraft(call, input, answer, nextIteration, logger);
    logger.readableInfo(formatEvaluation(nextIteration, evaluation));
    if (evaluation.satisfied) break;
    answer = await improvement(call, input, answer, evaluation.critique);
    logger.readableInfo(formatImprovement(nextIteration, answer));
  }
  logger.readableInfo(formatRefinementFinished(iterations, answer));
  return {answer, iterations};
}

export function createGenkitIterativeRefinementExecutor(
  ai: GenkitBeta,
  attachmentWorkspace?: NodeAttachmentWorkspace,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
): IterativeRefinementExecutor {
  return {execute: (input) => executeIterativeRefinementNode(ai, input, attachmentWorkspace, logger)};
}

/** Erst mit Ausgabeschema; scheitert das, bewertet das Modell als Text (JSON wird herausgelesen). */
async function evaluateDraft(
  call: RefinementCall, input: IterativeRefinementNodeInput, draft: string, iteration: number, logger: ApplicationLogger,
): Promise<Evaluation> {
  try {
    return await structuredEvaluation(call, input, draft, iteration);
  } catch (error) {
    logger.readableError(formatException({
      title: "Iterative Verfeinerung: strukturierte Bewertung fehlgeschlagen",
      error,
      context: [`Iteration: ${iteration}`, "Fallback: Textbewertung wird versucht."],
    }));
    logger.error("iterative_refinement.structured_evaluation_exception", {iteration, error: errorDetails(error)});
    return textEvaluation(call, input, draft, iteration);
  }
}

function boundedIterations(value: number): number {
  return Math.min(Math.max(value, 1), 5);
}
