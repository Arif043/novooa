import {type BranchWorkflowGraph} from "../entities/task.js";

export type GraphNode = {id: string; primitive: string; config?: unknown};

/** Alle Bausteine eines Plans, auch die in Verzweigungen und Schleifen. */
export function allNodesOf(graph: {nodes: readonly GraphNode[]}): GraphNode[] {
  return graph.nodes.flatMap((node) => [node, ...nestedNodesOf(node)]);
}

function nestedNodesOf(node: GraphNode): GraphNode[] {
  const config = record(node.config);
  const graphs: Array<BranchWorkflowGraph | undefined> = [];
  if (config.primitive === "forEach") graphs.push(graphOf(config.graph));
  if (config.primitive === "conditionalFlow" && Array.isArray(config.branches)) {
    for (const branch of config.branches) graphs.push(graphOf(record(branch).graph));
  }
  return graphs.flatMap((graph) => (graph === undefined ? [] : allNodesOf(graph)));
}

function graphOf(value: unknown): BranchWorkflowGraph | undefined {
  const graph = record(value);
  return Array.isArray(graph.nodes) ? graph as unknown as BranchWorkflowGraph : undefined;
}

export function record(value: unknown): Record<string, unknown> {
  return typeof value === "object" && value !== null ? value as Record<string, unknown> : {};
}
