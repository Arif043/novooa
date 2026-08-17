import {type GenkitBeta} from "genkit/beta";
import {
  type NodeExecutionResult,
  type NodeOutputValue,
  type TaskDefinition as Task,
  type WorkflowNode,
} from "./task-definition.js";
import {type TaskRunInteraction} from
  "../../../domain/entities/task-run-interaction.js";
import {type NodeAttachmentWorkspace} from "./node-attachment-workspace.js";
import {type TeamFileStore} from "../../../../files/domain/repositories/team-file-store.js";
import {type TaskMessageSender} from "../../../domain/repositories/task-message-sender.js";

export type TaskVariables = Record<string, unknown>;

export type SubgraphRunner = (
  task: Task,
  context: string,
) => Promise<NodeExecutionResult[]>;

export type TaskRunContext = {
  variables: TaskVariables;
  task: Task;
  teamId: string;
  input: Record<string, unknown>;
  results: Map<string, NodeExecutionResult>;
  runSubgraph: SubgraphRunner;
  resolveTemplates: (text: string) => string;
  teamFileStore: TeamFileStore;
  messageSender: TaskMessageSender;
};

export type NodeExecutorInput = {
  ai: GenkitBeta;
  node: WorkflowNode;
  context: string;
  attachmentWorkspace?: NodeAttachmentWorkspace;
};

export type NodeExecutor = {
  primitive: WorkflowNode["primitive"];
  execute(
    input: NodeExecutorInput,
    runContext: TaskRunContext,
  ): Promise<NodeExecutionResult>;
};

export function executedNode(
  node: WorkflowNode,
  outputs: Record<string, NodeOutputValue>,
  options: {
    selectedNodeId?: string | null;
    selection?: {
      selectedBranchId?: string | null;
      selectedBranchLabel?: string | null;
    };
    variables?: TaskVariables;
  } = {},
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "executed",
    outputs,
    variables: options.variables,
    selectedNodeId: options.selectedNodeId,
    selectedBranchId: options.selection?.selectedBranchId,
    selectedBranchLabel: options.selection?.selectedBranchLabel,
  };
}

export function skippedNode(node: WorkflowNode): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "skipped",
    outputs: {},
    message: "Baustein-Executor ist noch nicht implementiert.",
  };
}

export function waitingForInteractionNode(
  node: WorkflowNode,
  outputs: Record<string, NodeOutputValue>,
  interaction: TaskRunInteraction,
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "waitingForApproval",
    outputs,
    message: interaction.instruction,
    interaction,
  };
}

export function parentOutputFor(
  node: WorkflowNode,
  task: Task,
  results: Map<string, NodeExecutionResult>,
): string {
  const parentOutputs = parentResultsFor(node, task, results)
    .map((parentResult) => textOutputFromResult(parentResult.result))
    .filter((output) => output.trim().length > 0);
  return parentOutputs[parentOutputs.length - 1] ?? "";
}

export function stringOutput(value: string): NodeOutputValue {
  return {type: "string", value};
}

export function datetimeOutput(value: string): NodeOutputValue {
  return {type: "datetime", value};
}

export function textOutputs(text: string): Record<string, NodeOutputValue> {
  return text.trim().length === 0 ? {} : {text: stringOutput(text)};
}

export function textOutputFromResult(result: NodeExecutionResult): string {
  const text = result.outputs.text?.value;
  if (typeof text === "string") return text;
  const dataUrl = result.outputs.dataUrl?.value;
  return typeof dataUrl === "string" ? dataUrl : "";
}

export function parentResultsFor(
  node: WorkflowNode,
  task: Task,
  results: Map<string, NodeExecutionResult>,
) {
  return task.edges
    .filter((edge) => edge.to === node.id)
    .map((edge) => ({edge, result: results.get(edge.from)}))
    .filter((parent) => parent.result !== undefined) as {
      edge: Task["edges"][number];
      result: NodeExecutionResult;
    }[];
}
