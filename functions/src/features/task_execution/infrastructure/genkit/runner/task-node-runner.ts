import {type GenkitBeta} from "genkit/beta";
import {type KnowledgeBaseStore} from
  "../../../../knowledge_base/domain/repositories/knowledge-base-store.js";
import {type ObjectStore} from "../../../../files/domain/repositories/object-store.js";
import {type GenkitLanguageModelResolver} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {executorFor} from "./node-executor-registry.js";
import {
  parentResultsFor,
  skippedNode,
  type ParentNodeOutput,
  type TaskRunContext,
} from "../../../domain/executors/node-executor.js";
import {prepareNodeAttachmentWorkspace} from "./node-attachment-workspace.js";
import {
  type NodeExecutionResult,
  type WorkflowGraph,
  type WorkflowNode,
} from "./task-definition.js";
import {
  errorDetails,
  formatNodeFailed,
  formatNodeHeader,
  formatNodeTrail,
} from "./structured-logger.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

type NodeRunInput = {
  node: WorkflowNode;
  context: string;
  parentOutputs: ParentNodeOutput[];
  runContext: TaskRunContext;
  skipNode: boolean;
  startedAt: number;
  objectStore: ObjectStore;
  knowledgeBaseStore: KnowledgeBaseStore;
  languageModelResolver?: GenkitLanguageModelResolver;
  logger: ApplicationLogger;
};

export async function runNodeWithTrail(
  ai: GenkitBeta,
  input: NodeRunInput,
): Promise<NodeExecutionResult> {
  try {
    const result = input.skipNode
      ? skippedNode(input.node)
      : await executeNode(ai, input);
    logNodeTrail(input.logger, result, input.startedAt);
    return result;
  } catch (error) {
    logNodeErrorTrail(input, error);
    throw error;
  }
}

export function logNodeHeaderLine(
  logger: ApplicationLogger,
  node: WorkflowNode,
  taskId: string,
  graph: WorkflowGraph,
  context: string,
  skipNode: boolean,
  results: Map<string, NodeExecutionResult>,
): void {
  logger.readableInfo(formatNodeHeader({
    taskId,
    node,
    context,
    parentNodeIds: parentResultsFor(node, graph, results).map(
      (parent) => parent.result.nodeId,
    ),
    skipNode,
  }));
}

export function logSkippedBranches(
  logger: ApplicationLogger,
  node: WorkflowNode,
  taskId: string,
  result: NodeExecutionResult,
  skippedNodeIds: Set<string>,
): void {
  if (result.selectedNodeId === undefined) return;
  logger.readableInfo([
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
  const attachmentWorkspace = await prepareNodeAttachmentWorkspace(
    input.node,
    input.runContext.teamId,
    input.objectStore,
    input.knowledgeBaseStore,
  );
  try {
    const executor = executorFor(
      input.node.primitive,
      ai,
      input.logger,
      attachmentWorkspace,
      input.languageModelResolver,
    );
    if (!executor) return skippedNode(input.node);
    return await executor.execute({
      node: input.node,
      context: input.context,
      parentOutputs: input.parentOutputs,
    }, input.runContext);
  } finally {
    await attachmentWorkspace?.cleanup();
  }
}

function logNodeTrail(
  logger: ApplicationLogger,
  result: NodeExecutionResult,
  startedAt: number,
): void {
  logger.readableInfo(formatNodeTrail({
    result,
    durationMs: Date.now() - startedAt,
  }));
}

function logNodeErrorTrail(input: NodeRunInput, error: unknown): void {
  input.logger.readableError(formatNodeFailed({
    node: input.node,
    durationMs: Date.now() - input.startedAt,
    error,
  }));
  input.logger.error("task_node.exception", {
    taskId: input.runContext.task.id,
    nodeId: input.node.id,
    primitive: input.node.primitive,
    title: input.node.title,
    error: errorDetails(error),
  });
}
