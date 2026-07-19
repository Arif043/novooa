import {type GenkitBeta} from "genkit/beta";
import {type KnowledgeBaseStore} from
  "../domain/repositories/knowledge-base-store.js";
import {type ObjectStore} from "../domain/repositories/object-store.js";
import {executorFor} from "./node-executor-registry.js";
import {
  parentResultsFor,
  skippedNode,
  type TaskRunContext,
} from "./node-executor.js";
import {prepareNodeAttachmentWorkspace} from "./node-attachment-workspace.js";
import {
  type NodeExecutionResult,
  type TaskDefinition as Task,
  type WorkflowNode,
} from "./task-definition.js";
import {
  errorDetails,
  formatNodeFailed,
  formatNodeHeader,
  formatNodeTrail,
  logError,
  logReadableError,
  logReadableInfo,
} from "./structured-logger.js";

type NodeRunInput = {
  node: WorkflowNode;
  context: string;
  runContext: TaskRunContext;
  skipNode: boolean;
  startedAt: number;
  objectStore: ObjectStore;
  knowledgeBaseStore: KnowledgeBaseStore;
};

export async function runNodeWithTrail(
  ai: GenkitBeta,
  input: NodeRunInput,
): Promise<NodeExecutionResult> {
  try {
    const result = input.skipNode
      ? skippedNode(input.node)
      : await executeNode(ai, input);
    logNodeTrail(result, input.startedAt);
    return result;
  } catch (error) {
    logNodeErrorTrail(input, error);
    throw error;
  }
}

export function logNodeHeaderLine(
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

export function logSkippedBranches(
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

async function executeNode(
  ai: GenkitBeta,
  input: NodeRunInput,
): Promise<NodeExecutionResult> {
  const executor = executorFor(input.node.primitive);
  if (!executor) return skippedNode(input.node);
  const attachmentWorkspace = await prepareNodeAttachmentWorkspace(
    input.node,
    input.runContext.teamId,
    input.objectStore,
    input.knowledgeBaseStore,
  );
  try {
    return await executor.execute({
      ai,
      node: input.node,
      context: input.context,
      attachmentWorkspace,
    }, input.runContext);
  } finally {
    await attachmentWorkspace?.cleanup();
  }
}

function logNodeTrail(
  result: NodeExecutionResult,
  startedAt: number,
): void {
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
