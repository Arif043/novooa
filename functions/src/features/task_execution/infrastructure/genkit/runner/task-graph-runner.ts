import { type GenkitBeta } from "genkit/beta";
import {
  type SubgraphRunner,
  type ParentNodeOutput,
  type TaskRunContext,
  type TaskVariables,
} from "../../../domain/executors/node-executor.js";
import {
  type NodeExecutionResult,
  type NodeOutputValue,
  type TaskGraphInput,
  type TaskGraphOutput,
  type TaskDefinition as Task,
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
import {parentOutputsFor} from "../../../domain/executors/node-executor.js";
import {
  formatTaskFinished,
  formatTaskStarted,
  logReadableInfo,
} from "./structured-logger.js";
import {
  logNodeHeaderLine,
  logSkippedBranches,
  runNodeWithTrail,
} from "./task-node-runner.js";
import {
  resolveVariableTemplates,
  variableTemplateContextFor,
} from "./variable-template.js";
import {type TaskGraphRuntime} from "./task-graph-runtime.js";
import {updateTaskVariables} from "./task-run-variables.js";
export async function executeTaskGraph(
  ai: GenkitBeta,
  input: TaskGraphInput,
  runtime: TaskGraphRuntime,
): Promise<TaskGraphOutput> {
  logReadableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  const runState = await runNodes(ai, input, runtime);
  if (runState.status === "waitingForApproval") {
    return pausedOutput(input, runState);
  }
  const results = runState.nodeResults;
  const output = completedOutput(input, results);
  logReadableInfo(formatTaskFinished(
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
  logReadableInfo(formatTaskStarted(input.taskDefinition, input.context));
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
  initialParentOutputs: readonly ParentNodeOutput[] = [],
): Promise<NodeRunState> {
  const remaining = remainingNodes(input.taskDefinition, initialState);
  const results = resultsMapFrom(initialState?.nodeResults ?? []);
  const skippedNodeIds = new Set(initialState?.skippedNodeIds ?? []);
  const variables = {...initialState?.variables};

  while (remaining.length > 0) {
    const index = nextRunnableIndex(
      remaining,
      input.taskDefinition.edges,
      results,
    );
    if (index === -1) throw new Error("Task graph contains a cycle.");
    const node = remaining.splice(index, 1)[0];
    const context = contextFor(variables);
    const parentOutputs = parentOutputsFor(
      node,
      input.taskDefinition,
      results,
    );
    const effectiveParentOutputs = parentOutputs.length === 0
      && input.taskDefinition.edges.every((edge) => edge.to !== node.id)
      ? [...initialParentOutputs]
      : parentOutputs;
    const skipNode = shouldSkipNode(
      node,
      input.taskDefinition,
      results,
      skippedNodeIds,
    );
    const startedAt = Date.now();
    logNodeHeaderLine(node, input.taskDefinition, context, skipNode, results);
    const result = await runNodeWithTrail(ai, {
      node,
      context,
      parentOutputs: effectiveParentOutputs,
      runContext: runContextFor(ai, input, runtime, results, variables),
      skipNode,
      startedAt,
      objectStore: runtime.objectStore,
      knowledgeBaseStore: runtime.knowledgeBaseStore,
    });
    updateTaskVariables(variables, result);
    results.set(node.id, result);
    skipInactiveBranches(node, input.taskDefinition, result, skippedNodeIds);
    logSkippedBranches(node, input.taskDefinition.id, result, skippedNodeIds);
    if (result.status === "waitingForApproval") {
      return {
        status: "waitingForApproval",
        nodeResults: orderedResults(input.taskDefinition, results),
        variables: {...variables},
        remainingNodeIds: remaining.map((item) => item.id),
        skippedNodeIds: Array.from(skippedNodeIds),
        waitingNodeId: node.id,
      };
    }
  }

  return {
    status: "completed",
    nodeResults: orderedResults(input.taskDefinition, results),
  };
}
function runSubgraphFor(
  ai: GenkitBeta,
  variables: TaskVariables,
  teamId: string,
  runtime: TaskGraphRuntime,
): SubgraphRunner {
  return async (task: Task, context: string, initialValue?: NodeOutputValue) => {
    const state = await runNodes(ai, {
      taskDefinition: task,
      context,
      teamId,
      input: {},
    }, runtime, {
      nodeResults: [],
      variables,
      remainingNodeIds: task.nodes.map((node) => node.id),
      skippedNodeIds: [],
    }, initialValue === undefined ? [] : [{
      nodeId: "$iteration",
      outputName: "value",
      value: initialValue,
    }]);
    return state.nodeResults;
  };
}

function runContextFor(
  ai: GenkitBeta,
  input: TaskGraphInput,
  runtime: TaskGraphRuntime,
  results: Map<string, NodeExecutionResult>,
  variables: TaskVariables,
): TaskRunContext {
  return {
    task: input.taskDefinition,
    teamId: input.teamId,
    input: input.input ?? {},
    results,
    variables,
    teamFileStore: runtime.teamFileStore,
    fileContentReader: runtime.fileContentReader,
    messageSender: runtime.messageSender,
    modelInference: runtime.modelInference,
    runSubgraph: runSubgraphFor(ai, variables, input.teamId, runtime),
    resolveTemplates: (text: string) => resolveVariableTemplates(
      text,
      variableTemplateContextFor(input.taskDefinition, results, variables),
    ),
  };
}
