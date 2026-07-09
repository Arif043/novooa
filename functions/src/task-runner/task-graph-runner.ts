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
  type RunTaskDefinitionOutput,
  type TaskDefinition as Task,
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
import {type TaskVariables} from "./node-executor.js";
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
): Promise<RunTaskDefinitionOutput> {
  logReadableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  const results = await runNodes(ai, input);
  const output = {
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

async function runNodes(
  ai: Genkit,
  input: TaskGraphInput,
  variables: TaskVariables = {},
): Promise<NodeExecutionResult[]> {
  const remaining = [...input.taskDefinition.nodes];
  const results = new Map<string, NodeExecutionResult>();
  const skippedNodeIds = new Set<string>();

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
    const result = await runNodeWithTrail(
      ai,
      {node, context, task: input.taskDefinition, results, variables, skipNode, startedAt},
    );
    updateVariables(variables, result);
    results.set(node.id, result);
    skipInactiveBranches(node, input.taskDefinition, result, skippedNodeIds);
    logSkippedBranches(node, input.taskDefinition.id, result, skippedNodeIds);
    if (result.status === "waitingForApproval") {
      skipRemainingNodes(remaining, results, result.output);
      break;
    }
  }

  return input.taskDefinition.nodes.map((node) => results.get(node.id)!);
}

function skipRemainingNodes(
  remaining: WorkflowNode[],
  results: Map<string, NodeExecutionResult>,
  context: string,
): void {
  for (const node of remaining) {
    results.set(node.id, skippedNode(node, context));
  }
  remaining.length = 0;
}

type NodeRunInput = {
  node: WorkflowNode;
  context: string;
  task: Task;
  results: Map<string, NodeExecutionResult>;
  variables: TaskVariables;
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
    logNodeTrail(input.task.id, result, input.startedAt);
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
    taskId: input.task.id,
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

function runSubgraphFor(ai: Genkit, variables: TaskVariables) {
  return (task: Task, context: string) => runNodes(ai, {
    taskDefinition: task,
    context,
  }, variables);
}

async function executeNode(
  ai: Genkit,
  input: NodeRunInput,
): Promise<NodeExecutionResult> {
  const executor = executorFor(input.node.primitive);
  if (!executor) return skippedNode(input.node, input.context);
  const attachmentWorkspace = await prepareNodeAttachmentWorkspace(input.node);
  try {
    return await executor.execute({
      ai,
      node: input.node,
      context: input.context,
      variables: input.variables,
      task: input.task,
      results: input.results,
      runSubgraph: runSubgraphFor(ai, input.variables),
      attachmentWorkspace,
    });
  } finally {
    await attachmentWorkspace?.cleanup();
  }
}

function updateVariables(
  variables: TaskVariables,
  result: NodeExecutionResult,
): void {
  if (result.variables === undefined) return;
  for (const key of Object.keys(variables)) delete variables[key];
  Object.assign(variables, result.variables);
}
