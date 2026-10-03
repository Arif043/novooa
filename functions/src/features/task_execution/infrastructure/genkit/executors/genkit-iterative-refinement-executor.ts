import {type GenkitBeta} from "genkit/beta";
import {type IterativeRefinementExecutor} from "../../../domain/executors/iterative-refinement-executor.js";
import {
  type IterativeRefinementRequest,
  type IterativeRefinementResult,
} from "../../../domain/entities/iterative-refinement-execution.js";
import {modelLogContext, reasoningModel} from "../runner/ai-models.js";
import {
  type NodeExecutor,
  executedNode,
  textOutputs,
} from "../../../domain/executors/node-executor.js";
import {refinementConfigFor} from "./iterative-refinement-config.js";
import {
  type Evaluation,
  evaluationSchema,
  parseEvaluation,
} from "./iterative-refinement-evaluation.js";
import {
  formatEvaluation,
  formatImprovement,
  formatRefinementFinished,
  formatRefinementStarted,
} from "./iterative-refinement-format.js";
import {
  evaluationPrompt,
  improvementPrompt,
} from "./iterative-refinement-prompts.js";
import {
  formatException,
  formatModelCallFinished,
  formatModelCallStarted,
} from "../runner/structured-logger.js";
import {aiTurnMiddleware} from "../runner/node-attachment-genkit.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {runEmployeeAgentTurn} from "../runner/employee-agent.js";
import {
  errorDetails,
  type ApplicationLogger,
} from "../../../../../shared/logging/application-logger.js";
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
      return executedNode(node, textOutputs(output.answer));
    },
  };
}

export async function executeIterativeRefinementNode(
  ai: GenkitBeta,
  input: IterativeRefinementNodeInput,
  attachmentWorkspace?: NodeAttachmentWorkspace,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
): Promise<IterativeRefinementNodeOutput> {
  const maxIterations = boundedIterations(input.maxIterations);
  let answer = input.draft;
  let iterations = 0;

  logger.readableInfo(formatRefinementStarted(input, maxIterations));
  for (let nextIteration = 1; nextIteration <= maxIterations; nextIteration += 1) {
    iterations = nextIteration;
    const evaluation = await evaluateDraft(
      ai,
      input,
      answer,
      nextIteration,
      attachmentWorkspace,
      logger,
    );
    logger.readableInfo(formatEvaluation(nextIteration, evaluation));
    if (evaluation.satisfied) break;
    answer = await improveDraft(
      ai,
      input,
      answer,
      evaluation.critique,
      attachmentWorkspace,
      logger,
    );
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

async function evaluateDraft(
  ai: GenkitBeta,
  input: IterativeRefinementNodeInput,
  draft: string,
  iteration: number,
  attachmentWorkspace?: NodeAttachmentWorkspace,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
): Promise<Evaluation> {
  try {
    return await structuredEvaluation(
      ai,
      input,
      draft,
      iteration,
      attachmentWorkspace,
      logger,
    );
  } catch (error) {
    logger.readableError(formatException({
      title: "Iterative Verfeinerung: strukturierte Bewertung fehlgeschlagen",
      error,
      context: [
        `Iteration: ${iteration}`,
        "Fallback: Textbewertung wird versucht.",
      ],
    }));
    logger.error("iterative_refinement.structured_evaluation_exception", {
      iteration,
      error: errorDetails(error),
    });
    return textEvaluationFallback(
      ai,
      input,
      draft,
      iteration,
      attachmentWorkspace,
      logger,
    );
  }
}

async function structuredEvaluation(
  ai: GenkitBeta,
  input: IterativeRefinementNodeInput,
  draft: string,
  iteration: number,
  attachmentWorkspace?: NodeAttachmentWorkspace,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
): Promise<Evaluation> {
  const prompt = evaluationPrompt(input, draft);
  const startedAt = Date.now();
  const label = input.employee
    ? `Iterative Verfeinerung / Bewertung ${iteration} (Mitarbeiter: ${input.employee.name})`
    : `Iterative Verfeinerung / Bewertung ${iteration}`;
  logger.readableInfo(formatModelCallStarted({
    label,
    model: modelLogContext(),
    prompt,
    outputSchema: "critique: string, satisfied: boolean",
  }));

  let output: Evaluation | undefined | null;
  let logText = "";
  if (input.employee) {
    const response = await runEmployeeAgentTurn(ai, {
      employee: input.employee,
      model: reasoningModel(),
      prompt,
      output: {schema: evaluationSchema},
      use: aiTurnMiddleware(attachmentWorkspace),
    });
    output = response.data ?? undefined;
    logText = response.text;
  } else {
    const response = await ai.generate({
      model: reasoningModel(),
      prompt,
      output: {schema: evaluationSchema},
      use: aiTurnMiddleware(attachmentWorkspace),
    });
    output = response.output ?? undefined;
    logText = response.text;
  }
  logger.readableInfo(formatModelCallFinished({
    label,
    durationMs: Date.now() - startedAt,
    text: logText,
    output,
  }));
  if (!output) throw new Error("Evaluation returned no output.");
  return output;
}

async function textEvaluationFallback(
  ai: GenkitBeta,
  input: IterativeRefinementNodeInput,
  draft: string,
  iteration: number,
  attachmentWorkspace?: NodeAttachmentWorkspace,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
): Promise<Evaluation> {
  const prompt = `${evaluationPrompt(input, draft)}\n\nAntwort als JSON.`;
  const startedAt = Date.now();
  const label = input.employee
    ? `Iterative Verfeinerung / Bewertungs-Fallback ${iteration} (Mitarbeiter: ${input.employee.name})`
    : `Iterative Verfeinerung / Bewertungs-Fallback ${iteration}`;
  logger.readableInfo(formatModelCallStarted({
    label,
    model: modelLogContext(),
    prompt,
  }));

  const text = input.employee
    ? (await runEmployeeAgentTurn(ai, {
      employee: input.employee,
      model: reasoningModel(),
      prompt,
      use: aiTurnMiddleware(attachmentWorkspace),
    })).text
    : (await ai.generate({
      model: reasoningModel(),
      prompt,
      use: aiTurnMiddleware(attachmentWorkspace),
    })).text;

  logger.readableInfo(formatModelCallFinished({
    label,
    durationMs: Date.now() - startedAt,
    text,
  }));
  return parseEvaluation(text);
}

async function improveDraft(
  ai: GenkitBeta,
  input: IterativeRefinementNodeInput,
  draft: string,
  critique: string,
  attachmentWorkspace?: NodeAttachmentWorkspace,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
): Promise<string> {
  const prompt = improvementPrompt(input, draft, critique);
  const startedAt = Date.now();
  const label = input.employee
    ? `Iterative Verfeinerung / Optimierung (Mitarbeiter: ${input.employee.name})`
    : "Iterative Verfeinerung / Optimierung";
  logger.readableInfo(formatModelCallStarted({
    label,
    model: modelLogContext(),
    prompt,
  }));

  const text = input.employee
    ? (await runEmployeeAgentTurn(ai, {
      employee: input.employee,
      model: reasoningModel(),
      prompt,
      config: {temperature: 0.4},
      use: aiTurnMiddleware(attachmentWorkspace),
    })).text
    : (await ai.generate({
      model: reasoningModel(),
      prompt,
      config: {temperature: 0.4},
      use: aiTurnMiddleware(attachmentWorkspace),
    })).text;

  logger.readableInfo(formatModelCallFinished({
    label,
    durationMs: Date.now() - startedAt,
    text,
  }));
  return text;
}

function boundedIterations(value: number): number {
  return Math.min(Math.max(value, 1), 5);
}
