import {type Genkit} from "genkit";
import {
  type NodeExecutionResult,
  type TaskDefinition as Task,
  type WorkflowNode,
} from "./task-definition.js";

export type SubgraphRunner = (
  task: Task,
  context: string,
) => Promise<NodeExecutionResult[]>;

export type NodeExecutorInput = {
  ai: Genkit;
  node: WorkflowNode;
  context: string;
  task: Task;
  results: Map<string, NodeExecutionResult>;
  runSubgraph: SubgraphRunner;
};

export type NodeExecutor = {
  primitive: WorkflowNode["primitive"];
  execute(input: NodeExecutorInput): Promise<NodeExecutionResult>;
};

export function executedNode(
  node: WorkflowNode,
  output: string,
  selectedNodeId?: string | null,
  selection?: {
    selectedBranchId?: string | null;
    selectedBranchLabel?: string | null;
  },
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "executed",
    output,
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
    message: "Baustein-Executor ist noch nicht implementiert.",
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
