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
import {err, ok, type Result, ResultAsync} from "neverthrow";
import {formatTaskFinished, formatTaskStarted} from "./structured-logger.js";
import {
  logNodeHeaderLine,
  logSkippedBranches,
  runNodeWithTrail,
} from "./task-node-runner.js";
import {type TaskGraphRuntime} from "./task-graph-runtime.js";
import {updateTaskVariables} from "./task-run-variables.js";
import {createTaskRunContext} from "./workflow-graph-run-context.js";
export function executeTaskGraph(
  ai: GenkitBeta,
  input: TaskGraphInput,
  runtime: TaskGraphRuntime,
): ResultAsync<TaskGraphOutput, NodeExecutionFailure> {
  runtime.logger.readableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  return new ResultAsync(runNodes(ai, input, runtime))
    .map((runState) => finishedOutput(input, runState, runtime));
}

export function resumeTaskGraph(
  ai: GenkitBeta,
  input: TaskGraphInput,
  resumeState: TaskResumeState,
  responseOutputs: Record<string, NodeOutputValue>,
  runtime: TaskGraphRuntime,
): ResultAsync<TaskGraphOutput, NodeExecutionFailure> {
  runtime.logger.readableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  return new ResultAsync(runNodes(ai, input, runtime, resumedState(resumeState, responseOutputs)))
    .map((runState) => runState.status === "waitingForApproval"
      ? pausedOutput(input, runState)
      : completedOutput(input, runState.nodeResults));
}

function finishedOutput(input: TaskGraphInput, runState: NodeRunState, runtime: TaskGraphRuntime): TaskGraphOutput {
  if (runState.status === "waitingForApproval") return pausedOutput(input, runState);
  const results = runState.nodeResults;
  const output = completedOutput(input, results);
  runtime.logger.readableInfo(formatTaskFinished(
    output.taskId,
    results.filter((result) => result.status === "executed").length,
    results.filter((result) => result.status === "skipped").length,
    output.finalOutput.length,
  ));
  return output;
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
    // Die Executoren melden Fehler als Exception; hier, an der Grenze, wird daraus ein Failure-Wert.
    const resultOrFailure = await ResultAsync.fromPromise(runNodeWithTrail(ai, {
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
          return stateOrFailure.match(
            (state) => state.nodeResults,
            (failure) => { throw failure.cause; },
          );
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
      executorRegistry: runtime.executorRegistry,
      logger: runtime.logger,
    }), (error) => nodeExecutionFailure(node, error, newResults(graph, results, initialState)));
    if (resultOrFailure.isErr()) return err(resultOrFailure.error);
    const result = resultOrFailure.value;
    updateTaskVariables(variables, result);
    results.set(node.id, result);
    skipInactiveBranches(node, graph, result, skippedNodeIds);
    logSkippedBranches(runtime.logger, node, input.taskDefinition.id, result, skippedNodeIds);
    if (result.status === "waitingForApproval") {
      return ok({
        status: "waitingForApproval",
        nodeResults: orderedResults(graph, results),
        variables: {...variables},
        remainingNodeIds: remaining.map((item) => item.id),
        skippedNodeIds: Array.from(skippedNodeIds),
        waitingNodeId: node.id,
      });
    }
  }

  return ok({
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

function nodeExecutionFailure(node: WorkflowNode, error: unknown, completed: NodeExecutionResult[]): NodeExecutionFailure {
  const message = error instanceof Error ? error.message : String(error);
  const failedNode = {nodeId: node.id, primitive: node.primitive, message, console: consoleOutputOf(error)};
  return new NodeExecutionFailure(failedNode, completed, error);
}
