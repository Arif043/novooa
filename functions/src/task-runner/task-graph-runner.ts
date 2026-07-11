import { type Genkit } from "genkit";
import {executorFor} from "./node-executor-registry.js";
import {prepareNodeAttachmentWorkspace} from "./node-attachment-workspace.js";
import {
  parentResultsFor,
  skippedNode,
} from "./node-executor.js";
import {
  type NodeExecutionResult,
  type TaskGraphInput,
  type TaskGraphOutput,
  type TaskDefinition as Task,
  type TaskResumeState,
  type WorkflowNode,
} from "./task-definition.js";
import {
  contextFor,
  finalOutputOf,
  nextRunnableIndex,
  shouldSkipNode,
  skipInactiveBranches,
  validateGraph,
} from "./task-graph-utils.js";
import {
  type TaskRunContext,
  type TaskVariables,
} from "./node-executor.js";
import {
  formatNodeFailed,
  formatNodeHeader,
  formatNodeTrail,
  formatTaskFinished,
  formatTaskStarted,
  errorDetails,
  logError,
  logReadableError,
  logReadableInfo,
} from "./structured-logger.js";

export async function executeTaskGraph(
  ai: Genkit,
  input: TaskGraphInput,
): Promise<TaskGraphOutput> {
  logReadableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  const runState = await runNodes(ai, input);
  if (runState.status === "waitingForApproval") return pausedOutput(input, runState);
  const results = runState.nodeResults;
  const output = {
    status: "completed" as const,
    taskId: input.taskDefinition.id,
    finalOutput: finalOutputOf(results),
    nodeResults: results,
  };
  logReadableInfo(formatTaskFinished(
    output.taskId,
    results.filter((result) => result.status === "executed").length,
    results.filter((result) => result.status === "skipped").length,
    output.finalOutput.length,
  ));
  return output;
}

export async function resumeTaskGraph(
  ai: Genkit,
  input: TaskGraphInput,
  resumeState: TaskResumeState,
  approvedOutput: string,
): Promise<TaskGraphOutput> {
  logReadableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  const runState = await runNodes(
    ai,
    input,
    resumedState(resumeState, approvedOutput),
  );
  if (runState.status === "waitingForApproval") return pausedOutput(input, runState);
  return completedOutput(input, runState.nodeResults);
}

async function runNodes(
  ai: Genkit,
  input: TaskGraphInput,
  initialState?: InitialNodeRunState,
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
    const context = contextFor(node, input, results, variables);
    const skipNode = shouldSkipNode(
      node,
      input.taskDefinition,
      results,
      skippedNodeIds,
    );
    const startedAt = Date.now();
    logNodeHeader(node, input.taskDefinition, context, skipNode, results);
    const result = await runNodeWithTrail(ai, {
      node,
      context,
      runContext: runContextFor(ai, input, results, variables),
      skipNode,
      startedAt,
    });
    updateVariables(variables, result);
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

type InitialNodeRunState = {
  nodeResults: NodeExecutionResult[];
  variables: TaskVariables;
  remainingNodeIds: string[];
  skippedNodeIds: string[];
};

type NodeRunState = {
  status: "completed";
  nodeResults: NodeExecutionResult[];
} | ({
  status: "waitingForApproval";
} & TaskResumeState);

function orderedResults(
  task: Task,
  results: Map<string, NodeExecutionResult>,
): NodeExecutionResult[] {
  return task.nodes
    .map((node) => results.get(node.id))
    .filter((result): result is NodeExecutionResult => result !== undefined);
}

function pausedOutput(
  input: TaskGraphInput,
  state: Extract<NodeRunState, {status: "waitingForApproval"}>,
): TaskGraphOutput {
  return {
    status: "waitingForApproval",
    taskId: input.taskDefinition.id,
    finalOutput: finalOutputOf(state.nodeResults),
    nodeResults: state.nodeResults,
    resumeState: resumeStateFrom(state),
  };
}

function completedOutput(
  input: TaskGraphInput,
  results: NodeExecutionResult[],
): TaskGraphOutput {
  return {
    status: "completed",
    taskId: input.taskDefinition.id,
    finalOutput: finalOutputOf(results),
    nodeResults: results,
  };
}

function resumeStateFrom(
  state: Extract<NodeRunState, {status: "waitingForApproval"}>,
): TaskResumeState {
  return {
    nodeResults: state.nodeResults,
    variables: state.variables,
    remainingNodeIds: state.remainingNodeIds,
    skippedNodeIds: state.skippedNodeIds,
    waitingNodeId: state.waitingNodeId,
  };
}

function resumedState(
  state: TaskResumeState,
  approvedOutput: string,
): InitialNodeRunState {
  return {
    nodeResults: state.nodeResults.map((result) =>
      result.nodeId === state.waitingNodeId
        ? {...result, status: "executed", output: approvedOutput}
        : result,
    ),
    variables: state.variables,
    remainingNodeIds: state.remainingNodeIds,
    skippedNodeIds: state.skippedNodeIds,
  };
}

function remainingNodes(
  task: Task,
  state?: InitialNodeRunState,
): WorkflowNode[] {
  if (!state) return [...task.nodes];
  const remainingIds = new Set(state.remainingNodeIds);
  return task.nodes.filter((node) => remainingIds.has(node.id));
}

function resultsMapFrom(results: NodeExecutionResult[]) {
  return new Map(results.map((result) => [result.nodeId, result]));
}

type NodeRunInput = {
  node: WorkflowNode;
  context: string;
  runContext: TaskRunContext;
  skipNode: boolean;
  startedAt: number;
};

async function runNodeWithTrail(
  ai: Genkit,
  input: NodeRunInput,
): Promise<NodeExecutionResult> {
  try {
    const result = input.skipNode
      ? skippedNode(input.node, "")
      : await executeNode(ai, input);
    logNodeTrail(input.runContext.task.id, result, input.startedAt);
    return result;
  } catch (error) {
    logNodeErrorTrail(input, error);
    throw error;
  }
}

function logNodeHeader(
  node: WorkflowNode,
  task: Task,
  context: string,
  skipNode: boolean,
  results: Map<string, NodeExecutionResult>,
): void {
  logReadableInfo(formatNodeHeader({
    taskId: task.id,
    node,
    context,
    parentNodeIds: parentResultsFor(node, task, results).map(
      (parent) => parent.result.nodeId,
    ),
    skipNode,
  }));
}

function logNodeTrail(
  taskId: string,
  result: NodeExecutionResult,
  startedAt: number,
): void {
  void taskId;
  logReadableInfo(formatNodeTrail({
    result,
    durationMs: Date.now() - startedAt,
  }));
}

function logNodeErrorTrail(input: NodeRunInput, error: unknown): void {
  logReadableError(formatNodeFailed({
    node: input.node,
    durationMs: Date.now() - input.startedAt,
    error,
  }));
  logError("task_node.exception", {
    taskId: input.runContext.task.id,
    nodeId: input.node.id,
    primitive: input.node.primitive,
    title: input.node.title,
    error: errorDetails(error),
  });
}

function logSkippedBranches(
  node: WorkflowNode,
  taskId: string,
  result: NodeExecutionResult,
  skippedNodeIds: Set<string>,
): void {
  if (result.selectedNodeId === undefined) return;
  logReadableInfo([
    `[Verzweigung] ${node.title}`,
    `Aufgabe: ${taskId}`,
    `Gewählt: ${result.selectedBranchLabel ?? result.selectedNodeId ?? "-"}`,
    `Übersprungen: ${Array.from(skippedNodeIds).join(", ") || "-"}`,
  ].join("\n"));
}

function runSubgraphFor(ai: Genkit, variables: TaskVariables, teamId: string) {
  return async (task: Task, context: string) => {
    const state = await runNodes(ai, {
      taskDefinition: task,
      context,
      teamId,
    }, {
      nodeResults: [],
      variables,
      remainingNodeIds: task.nodes.map((node) => node.id),
      skippedNodeIds: [],
    });
    return state.nodeResults;
  };
}

async function executeNode(
  ai: Genkit,
  input: NodeRunInput,
): Promise<NodeExecutionResult> {
  const executor = executorFor(input.node.primitive);
  if (!executor) return skippedNode(input.node, input.context);
  const attachmentWorkspace = await prepareNodeAttachmentWorkspace(
    input.node,
    input.runContext.teamId,
  );
  try {
    return await executor.execute({
      ai,
      node: input.node,
      context: input.context,
      runContext: input.runContext,
      attachmentWorkspace,
    });
  } finally {
    await attachmentWorkspace?.cleanup();
  }
}

function runContextFor(
  ai: Genkit,
  input: TaskGraphInput,
  results: Map<string, NodeExecutionResult>,
  variables: TaskVariables,
): TaskRunContext {
  return {
    task: input.taskDefinition,
    teamId: input.teamId,
    results,
    variables,
    runSubgraph: runSubgraphFor(ai, variables, input.teamId),
  };
}

function updateVariables(
  variables: TaskVariables,
  result: NodeExecutionResult,
): void {
  if (result.variables === undefined) return;
  for (const key of Object.keys(variables)) delete variables[key];
  Object.assign(variables, result.variables);
}
