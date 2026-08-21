import {
  type NodeExecutionResult,
  type TaskDefinition,
  type WorkflowEdge,
  type WorkflowNode,
} from "./task-definition.js";
import {type TaskVariables} from "./node-executor.js";
import {textOutputFromResult} from "./node-executor.js";

export function nextRunnableIndex(
  nodes: WorkflowNode[],
  edges: WorkflowEdge[],
  results: Map<string, NodeExecutionResult>,
): number {
  return nodes.findIndex((node) => {
    const parents = edges.filter((edge) => edge.to === node.id);
    return parents.every((edge) => results.has(edge.from));
  });
}

export function contextFor(
  variables: TaskVariables,
): string {
  return variablesContext(variables);
}

function variablesContext(variables: TaskVariables): string {
  const entries = Object.entries(variables);
  if (entries.length === 0) return "";
  return [
    "Variablen:",
    ...entries.map(([key, value]) => `${key}: ${formatVariable(value)}`),
  ].join("\n");
}

function formatVariable(value: unknown): string {
  return typeof value === "string" ? value : JSON.stringify(value);
}

export function validateGraph(taskDefinition: TaskDefinition): void {
  const nodeIds = new Set<string>();
  for (const node of taskDefinition.nodes) {
    if (nodeIds.has(node.id)) {
      throw new Error(`Task graph contains a duplicate node: ${node.id}.`);
    }
    nodeIds.add(node.id);
  }
  for (const edge of taskDefinition.edges) {
    if (!nodeIds.has(edge.from) || !nodeIds.has(edge.to)) {
      throw new Error(
        `Task graph edge references an unknown node: ${edge.from}->${edge.to}.`,
      );
    }
  }
}

export function shouldSkipNode(
  node: WorkflowNode,
  taskDefinition: TaskDefinition,
  results: Map<string, NodeExecutionResult>,
  skippedNodeIds: Set<string>,
): boolean {
  if (skippedNodeIds.has(node.id)) return true;
  const parents = taskDefinition.edges.filter((edge) => edge.to === node.id);
  if (parents.length === 0) return false;
  return parents.every((edge) => results.get(edge.from)?.status === "skipped");
}

export function skipInactiveBranches(
  node: WorkflowNode,
  taskDefinition: TaskDefinition,
  result: NodeExecutionResult,
  skippedNodeIds: Set<string>,
): void {
  if (node.primitive !== "conditionalFlow") return;
  const outgoingEdges = taskDefinition.edges.filter((edge) => {
    return edge.from === node.id;
  });
  for (const edge of outgoingEdges) {
    if (edge.to !== result.selectedNodeId) skippedNodeIds.add(edge.to);
  }
}

export function finalOutputOf(results: NodeExecutionResult[]): string {
  for (let index = results.length - 1; index >= 0; index -= 1) {
    const text = textOutputFromResult(results[index]);
    if (text.trim().length > 0) return text;
  }
  return "";
}
