import { type GenkitBeta } from "genkit/beta";
import {type WorkflowExecutionScope} from "../../../domain/executors/node-executor.js";
import {
  type NodeExecutionResult,
  type NodeOutputValue,
  type WorkflowNode,
  type TaskGraphInput,
  type TaskGraphOutput,
  type WorkflowGraph,
  type TaskResumeState,
} from "./task-definition.js";
import {
  completedOutput,
  type InitialNodeRunState,
  type NodeRunState,
  orderedResults,
  pausedOutput,
  remainingNodes,
  resumedState,
  resultsMapFrom,
} from "./task-graph-state.js";
import {
  contextFor,
  nextRunnableIndex,
  shouldSkipNode,
  skipInactiveBranches,
  validateGraph,
} from "../../../domain/services/task-graph-utils.js";
import {consoleOutputOf} from "../../../domain/entities/script-execution.js";
import {NodeExecutionFailure} from "../../../domain/entities/node-execution-failure.js";
import {failure, type Result, success} from "../../../../../shared/result.js";
import {formatTaskFinished, formatTaskStarted} from "./structured-logger.js";
import {
  logNodeHeaderLine,
  logSkippedBranches,
  runNodeWithTrail,
} from "./task-node-runner.js";
import {type TaskGraphRuntime} from "./task-graph-runtime.js";
import {updateTaskVariables} from "./task-run-variables.js";
import {createTaskRunContext} from "./workflow-graph-run-context.js";
export async function executeTaskGraph(
  ai: GenkitBeta,
  input: TaskGraphInput,
  runtime: TaskGraphRuntime,
): Promise<Result<TaskGraphOutput, NodeExecutionFailure>> {
  runtime.logger.readableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  const runStateOrFailure = await runNodes(ai, input, runtime);
  if (!runStateOrFailure.ok) return runStateOrFailure;
  const runState = runStateOrFailure.value;
  if (runState.status === "waitingForApproval") {
    return success(pausedOutput(input, runState));
  }
  const results = runState.nodeResults;
  const output = completedOutput(input, results);
  runtime.logger.readableInfo(formatTaskFinished(
    output.taskId,
    results.filter((result) => result.status === "executed").length,
    results.filter((result) => result.status === "skipped").length,
    output.finalOutput.length,
  ));
  return success(output);
}

export async function resumeTaskGraph(
  ai: GenkitBeta,
  input: TaskGraphInput,
  resumeState: TaskResumeState,
  responseOutputs: Record<string, NodeOutputValue>,
  runtime: TaskGraphRuntime,
): Promise<Result<TaskGraphOutput, NodeExecutionFailure>> {
  runtime.logger.readableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  const runStateOrFailure = await runNodes(
    ai,
    input,
    runtime,
    resumedState(resumeState, responseOutputs),
  );
  if (!runStateOrFailure.ok) return runStateOrFailure;
  const runState = runStateOrFailure.value;
  if (runState.status === "waitingForApproval") {
    return success(pausedOutput(input, runState));
  }
  return success(completedOutput(input, runState.nodeResults));
}

async function runNodes(
  ai: GenkitBeta,
  input: TaskGraphInput,
  runtime: TaskGraphRuntime,
  initialState?: InitialNodeRunState,
  scope: WorkflowExecutionScope = {},
  graph: WorkflowGraph = input.taskDefinition,
): Promise<Result<NodeRunState, NodeExecutionFailure>> {
  const remaining = remainingNodes(graph, initialState);
  const results = resultsMapFrom(initialState?.nodeResults ?? []);
  const skippedNodeIds = new Set(initialState?.skippedNodeIds ?? []);
  const variables = {...initialState?.variables};

  while (remaining.length > 0) {
    const index = nextRunnableIndex(
      remaining,
      graph.edges,
      results,
    );
    if (index === -1) throw new Error("Task graph contains a cycle.");
    const node = remaining.splice(index, 1)[0];
    const context = contextFor(variables);
    const skipNode = shouldSkipNode(
      node,
      graph,
      results,
      skippedNodeIds,
    );
    const startedAt = Date.now();
    logNodeHeaderLine(runtime.logger, node, input.taskDefinition.id, graph, context, skipNode, results);
    const resultOrFailure = await attemptNode(() => runNodeWithTrail(ai, {
      node,
      context,
      runContext: createTaskRunContext({
        input,
        context,
        runtime,
        currentGraph: graph,
        results,
        variables,
        scope,
        executeGraph: async (embeddedGraph, embeddedContext, embeddedScope) => {
          const stateOrFailure = await runNodes(
            ai,
            input,
            runtime,
            {
              nodeResults: [],
              variables,
              remainingNodeIds: embeddedGraph.nodes.map((item) => item.id),
              skippedNodeIds: [],
            },
            embeddedScope,
            embeddedGraph,
          );
          // Die Executoren erwarten für einen verschachtelten Plan eine Exception; der äußere Baustein scheitert dann.
          if (!stateOrFailure.ok) throw stateOrFailure.failure.cause;
          return stateOrFailure.value.nodeResults;
        },
      }),
      skipNode,
      startedAt,
      objectStore: runtime.objectStore,
      skillContentReader: runtime.skillContentReader,
      employeeStore: runtime.employeeStore,
      knowledgeBaseStore: runtime.knowledgeBaseStore,
      languageModelResolver: runtime.languageModelResolver,
      languageModelDefaultsStore: runtime.languageModelDefaultsStore,
      scriptExecutorFactory: runtime.scriptExecutorFactory,
      logger: runtime.logger,
    }), (error) => nodeExecutionFailure(node, error, newResults(graph, results, initialState)));
    if (!resultOrFailure.ok) return resultOrFailure;
    const result = resultOrFailure.value;
    updateTaskVariables(variables, result);
    results.set(node.id, result);
    skipInactiveBranches(node, graph, result, skippedNodeIds);
    logSkippedBranches(runtime.logger, node, input.taskDefinition.id, result, skippedNodeIds);
    if (result.status === "waitingForApproval") {
      return success({
        status: "waitingForApproval",
        nodeResults: orderedResults(graph, results),
        variables: {...variables},
        remainingNodeIds: remaining.map((item) => item.id),
        skippedNodeIds: Array.from(skippedNodeIds),
        waitingNodeId: node.id,
      });
    }
  }

  return success({
    status: "completed",
    nodeResults: orderedResults(graph, results),
  });
}

/** Die Ergebnisse, die dieser Lauf selbst erzeugt hat; was aus einer früheren Freigabe stammt, steht schon in den Aktivitäten. */
function newResults(
  graph: WorkflowGraph,
  results: Map<string, NodeExecutionResult>,
  initialState?: InitialNodeRunState,
): NodeExecutionResult[] {
  const alreadyRecorded = new Set((initialState?.nodeResults ?? []).map((result) => result.nodeId));
  return orderedResults(graph, results).filter((result) => !alreadyRecorded.has(result.nodeId));
}

/**
 * Die Executoren der Bausteine melden Fehler als Exception. Hier, an der Grenze zur Infrastruktur,
 * wird daraus ein Failure-Wert; ab hier läuft nichts mehr über Exceptions.
 */
async function attemptNode(
  run: () => Promise<NodeExecutionResult>,
  failureOf: (error: unknown) => NodeExecutionFailure,
): Promise<Result<NodeExecutionResult, NodeExecutionFailure>> {
  try {
    return success(await run());
  } catch (error) {
    return failure(failureOf(error));
  }
}

function nodeExecutionFailure(node: WorkflowNode, error: unknown, completed: NodeExecutionResult[]): NodeExecutionFailure {
  const message = error instanceof Error ? error.message : String(error);
  const failedNode = {nodeId: node.id, primitive: node.primitive, message, console: consoleOutputOf(error)};
  return new NodeExecutionFailure(failedNode, completed, error);
}
