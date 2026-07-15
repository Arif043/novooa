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
  output: string,
  selectedNodeId?: string | null,
  selection?: {
    selectedBranchId?: string | null;
    selectedBranchLabel?: string | null;
  },
  variables?: TaskVariables,
  outputs?: Record<string, NodeOutputValue>,
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "executed",
    output,
    outputs: outputs ?? textOutputs(output),
    variables,
    selectedNodeId,
    selectedBranchId: selection?.selectedBranchId,
    selectedBranchLabel: selection?.selectedBranchLabel,
  };
}

export function skippedNode(
  node: WorkflowNode,
  context: string,
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "skipped",
    output: context,
    outputs: textOutputs(context),
    message: "Baustein-Executor ist noch nicht implementiert.",
  };
}

export function waitingForApprovalNode(
  node: WorkflowNode,
  output: string,
  message: string,
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "waitingForApproval",
    output,
    outputs: textOutputs(output),
    message,
  };
}

export function parentOutputFor(
  node: WorkflowNode,
  task: Task,
  results: Map<string, NodeExecutionResult>,
): string {
  const parentOutputs = parentResultsFor(node, task, results)
    .map((parentResult) => parentResult.result.output)
    .filter((output) => output.trim().length > 0);
  return parentOutputs[parentOutputs.length - 1] ?? "";
}

export function stringOutput(value: string): NodeOutputValue {
  return {type: "string", value};
}

export function datetimeOutput(value: string): NodeOutputValue {
  return {type: "datetime", value};
}

function textOutputs(output: string): Record<string, NodeOutputValue> {
  return output.trim().length === 0 ? {} : {text: stringOutput(output)};
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
