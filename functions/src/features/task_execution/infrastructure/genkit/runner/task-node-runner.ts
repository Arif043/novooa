import {ok} from "neverthrow";
import {type NodeResultOrFailure} from "../../../domain/executors/node-executor.js";
import {type EmployeeStore} from "../../../../employees/domain/repositories/employee-store.js";
import {type SkillContentReader} from "../../../../skills/domain/repositories/skill-content-reader.js";
import {type GenkitBeta} from "genkit/beta";
import {type KnowledgeBaseStore} from
  "../../../../knowledge_base/domain/repositories/knowledge-base-store.js";
import {type ObjectStore} from "../../../../files/domain/repositories/object-store.js";
import {type GenkitLanguageModelResolver} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../../../language_models/domain/repositories/language-model-defaults-store.js";
import {type ScriptExecutorFactory} from "../../../domain/executors/script-executor.js";
import {executorFor, type NodeExecutorRegistry} from "./node-executor-registry.js";
import {
  parentResultsFor,
  skippedNode,
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
  runContext: TaskRunContext;
  skipNode: boolean;
  startedAt: number;
  objectStore: ObjectStore;
  skillContentReader?: SkillContentReader;
  employeeStore?: EmployeeStore;
  knowledgeBaseStore: KnowledgeBaseStore;
  languageModelResolver?: GenkitLanguageModelResolver;
  languageModelDefaultsStore?: LanguageModelDefaultsStore;
  executorRegistry?: NodeExecutorRegistry;
  scriptExecutorFactory?: ScriptExecutorFactory;
  logger: ApplicationLogger;
};

export async function runNodeWithTrail(
  ai: GenkitBeta,
  input: NodeRunInput,
): Promise<NodeResultOrFailure> {
  try {
    const resultOrFailure = input.skipNode
      ? ok(skippedNode(input.node))
      : await executeNode(ai, input);
    resultOrFailure.match(
      (result) => logNodeTrail(input.logger, result, input.startedAt),
      (failure) => logNodeErrorTrail(input, failure),
    );
    return resultOrFailure;
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
  skipNode: boolean,
  results: Map<string, NodeExecutionResult>,
): void {
  logger.readableInfo(formatNodeHeader({
    taskId,
    node,
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
): Promise<NodeResultOrFailure> {
  const attachmentWorkspace = await prepareNodeAttachmentWorkspace(
    input.node,
    input.runContext.teamId,
    {
      objectStore: input.objectStore,
      knowledgeBaseStore: input.knowledgeBaseStore,
      skillContentReader: input.skillContentReader,
      employeeStore: input.employeeStore,
    },
  );
  try {
    const executor = executorFor(
      input.node.primitive,
      ai,
      input.logger,
      attachmentWorkspace,
      input.languageModelResolver,
      input.languageModelDefaultsStore,
      input.scriptExecutorFactory,
      input.executorRegistry,
    );
    if (!executor) return ok(skippedNode(input.node));
    return await executor.execute(input.node, input.runContext);
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
    taskId: input.runContext.rootTask.id,
    nodeId: input.node.id,
    primitive: input.node.primitive,
    title: input.node.title,
    error: errorDetails(error),
  });
}
