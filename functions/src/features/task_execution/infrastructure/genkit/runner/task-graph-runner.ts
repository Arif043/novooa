import { type GenkitBeta } from "genkit/beta";
import {type WorkflowExecutionScope} from "../../../domain/executors/node-executor.js";
import {
  type NodeOutputValue,
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
): Promise<TaskGraphOutput> {
  runtime.logger.readableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  const runState = await runNodes(ai, input, runtime);
  if (runState.status === "waitingForApproval") {
    return pausedOutput(input, runState);
  }
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

export async function resumeTaskGraph(
  ai: GenkitBeta,
  input: TaskGraphInput,
  resumeState: TaskResumeState,
  responseOutputs: Record<string, NodeOutputValue>,
  runtime: TaskGraphRuntime,
): Promise<TaskGraphOutput> {
  runtime.logger.readableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  const runState = await runNodes(
    ai,
    input,
    runtime,
    resumedState(resumeState, responseOutputs),
  );
  if (runState.status === "waitingForApproval") {
    return pausedOutput(input, runState);
  }
  return completedOutput(input, runState.nodeResults);
}

async function runNodes(
  ai: GenkitBeta,
  input: TaskGraphInput,
  runtime: TaskGraphRuntime,
  initialState?: InitialNodeRunState,
  scope: WorkflowExecutionScope = {},
  graph: WorkflowGraph = input.taskDefinition,
): Promise<NodeRunState> {
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
    const result = await runNodeWithTrail(ai, {
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
        executeGraph: async (embeddedGraph, embeddedContext, graphInput, embeddedScope) => {
          const state = await runNodes(
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
          return state.nodeResults;
        },
      }),
      skipNode,
      startedAt,
      objectStore: runtime.objectStore,
      skillContentReader: runtime.skillContentReader,
      knowledgeBaseStore: runtime.knowledgeBaseStore,
      languageModelResolver: runtime.languageModelResolver,
      languageModelDefaultsStore: runtime.languageModelDefaultsStore,
      logger: runtime.logger,
    });
    updateTaskVariables(variables, result);
    results.set(node.id, result);
    skipInactiveBranches(node, graph, result, skippedNodeIds);
    logSkippedBranches(runtime.logger, node, input.taskDefinition.id, result, skippedNodeIds);
    if (result.status === "waitingForApproval") {
      return {
        status: "waitingForApproval",
        nodeResults: orderedResults(graph, results),
        variables: {...variables},
        remainingNodeIds: remaining.map((item) => item.id),
        skippedNodeIds: Array.from(skippedNodeIds),
        waitingNodeId: node.id,
      };
    }
  }

  return {
    status: "completed",
    nodeResults: orderedResults(graph, results),
  };
}
