import {type Genkit} from "genkit";
import {
  type NodeExecutionResult,
  type NodeOutputValue,
  type TaskDefinition as Task,
  type WorkflowNode,
} from "./task-definition.js";
import {type NodeAttachmentWorkspace} from "./node-attachment-workspace.js";

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
};

export type NodeExecutorInput = {
  ai: Genkit;
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

export function waitingForApprovalNode(
  node: WorkflowNode,
  outputs: Record<string, NodeOutputValue>,
  message: string,
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "waitingForApproval",
    outputs,
    message,
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
  return typeof text === "string" ? text : "";
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
