import {type Genkit} from "genkit";
import {modelLogContext, reasoningModel} from "../task-runner/ai-models.js";
import {
  type NodeExecutor,
  executedNode,
  parentOutputFor,
} from "../task-runner/node-executor.js";
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
  errorDetails,
  formatException,
  formatModelCallFinished,
  formatModelCallStarted,
  logError,
  logReadableError,
  logReadableInfo,
} from "../task-runner/structured-logger.js";
import {aiTurnMiddleware} from "../task-runner/node-attachment-genkit.js";

export type IterativeRefinementNodeInput = {
  objective: string;
  draft: string;
  optimizerPrompt: string;
  critiquePrompt: string;
  maxIterations: number;
};

export type IterativeRefinementNodeOutput = {
  answer: string;
  iterations: number;
};

export const iterativeRefinementNodeExecutor: NodeExecutor = {
  primitive: "iterativeRefinement",
  async execute(input, runContext) {
    const config = refinementConfigFor(input.node);
    const draft = parentOutputFor(
      input.node,
      runContext.task,
      runContext.results,
    ) ||
      input.context;
    const output = await executeIterativeRefinementNode(input.ai, {
      objective: runContext.task.objective,
      draft,
      optimizerPrompt: config?.optimizerPrompt ||
        input.node.description ||
        input.node.title,
      critiquePrompt: config?.critiquePrompt ||
        input.node.description ||
        input.node.title,
      maxIterations: config?.maxIterations ?? 2,
    });
    return executedNode(input.node, output.answer);
  },
};

export async function executeIterativeRefinementNode(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
): Promise<IterativeRefinementNodeOutput> {
  const maxIterations = boundedIterations(input.maxIterations);
  let answer = input.draft;
  let iterations = 0;

  logReadableInfo(formatRefinementStarted(input, maxIterations));
  for (let nextIteration = 1; nextIteration <= maxIterations; nextIteration += 1) {
    iterations = nextIteration;
    const evaluation = await evaluateDraft(ai, input, answer, nextIteration);
    logReadableInfo(formatEvaluation(nextIteration, evaluation));
    if (evaluation.satisfied) break;
    answer = await improveDraft(ai, input, answer, evaluation.critique);
    logReadableInfo(formatImprovement(nextIteration, answer));
  }

  logReadableInfo(formatRefinementFinished(iterations, answer));
  return {answer, iterations};
}

async function evaluateDraft(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
  draft: string,
  iteration: number,
): Promise<Evaluation> {
  try {
    return await structuredEvaluation(ai, input, draft, iteration);
  } catch (error) {
    logReadableError(formatException({
      title: "Iterative Verfeinerung: strukturierte Bewertung fehlgeschlagen",
      error,
      context: [
        `Iteration: ${iteration}`,
        "Fallback: Textbewertung wird versucht.",
      ],
    }));
    logError("iterative_refinement.structured_evaluation_exception", {
      iteration,
      error: errorDetails(error),
    });
    return textEvaluationFallback(ai, input, draft, iteration);
  }
}

async function structuredEvaluation(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
  draft: string,
  iteration: number,
): Promise<Evaluation> {
  const prompt = evaluationPrompt(input, draft);
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label: `Iterative Verfeinerung / Bewertung ${iteration}`,
    model: modelLogContext(),
    prompt,
    outputSchema: "critique: string, satisfied: boolean",
  }));
  const response = await ai.generate({
    model: reasoningModel(),
    prompt,
    output: {schema: evaluationSchema},
    use: aiTurnMiddleware(),
  });
  logReadableInfo(formatModelCallFinished({
    label: `Iterative Verfeinerung / Bewertung ${iteration}`,
    durationMs: Date.now() - startedAt,
    text: response.text,
    output: response.output,
  }));
  if (!response.output) throw new Error("Evaluation returned no output.");
  return response.output;
}

async function textEvaluationFallback(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
  draft: string,
  iteration: number,
): Promise<Evaluation> {
  const prompt = `${evaluationPrompt(input, draft)}\n\nAntwort als JSON.`;
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label: `Iterative Verfeinerung / Bewertungs-Fallback ${iteration}`,
    model: modelLogContext(),
    prompt,
  }));
  const response = await ai.generate({
    model: reasoningModel(),
    prompt,
    use: aiTurnMiddleware(),
  });
  logReadableInfo(formatModelCallFinished({
    label: `Iterative Verfeinerung / Bewertungs-Fallback ${iteration}`,
    durationMs: Date.now() - startedAt,
    text: response.text,
  }));
  return parseEvaluation(response.text);
}

async function improveDraft(
  ai: Genkit,
  input: IterativeRefinementNodeInput,
  draft: string,
  critique: string,
): Promise<string> {
  const prompt = improvementPrompt(input, draft, critique);
  const startedAt = Date.now();
  logReadableInfo(formatModelCallStarted({
    label: "Iterative Verfeinerung / Optimierung",
    model: modelLogContext(),
    prompt,
  }));
  const response = await ai.generate({
    model: reasoningModel(),
    prompt,
    config: {temperature: 0.4},
    use: aiTurnMiddleware(),
  });
  logReadableInfo(formatModelCallFinished({
    label: "Iterative Verfeinerung / Optimierung",
    durationMs: Date.now() - startedAt,
    text: response.text,
  }));
  return response.text;
}

function boundedIterations(value: number): number {
  return Math.min(Math.max(value, 1), 5);
}
