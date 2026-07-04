import {type WorkflowEdge, type WorkflowNode} from "../task-runner/task-definition.js";

export type ConditionalNodeInput = {
  node: WorkflowNode;
  targetLabel: string;
  outgoingEdges: WorkflowEdge[];
};

export type ConditionalNodeOutput = {
  selectedNodeId: string | null;
  reason: string;
};

export function executeConditionalNode(
  input: ConditionalNodeInput,
): ConditionalNodeOutput {
  const targetLabel = normalizeLabel(input.targetLabel);
  const match = matchingEdgeFor(input, targetLabel);

  return {
    selectedNodeId: match?.edge.to ?? input.outgoingEdges[0]?.to ?? null,
    reason: match
      ? `Matched target label: ${match.label}`
      : `No target label matched: ${input.targetLabel}. Used first branch.`,
  };
}

function matchingEdgeFor(input: ConditionalNodeInput, targetLabel: string) {
  for (const [index, edge] of input.outgoingEdges.entries()) {
    const label = edgeLabel(input.node, edge, index);
    if (normalizeLabel(label) === targetLabel) return {edge, label};
  }
  return undefined;
}

function edgeLabel(
  node: WorkflowNode,
  edge: WorkflowEdge,
  index: number,
): string {
  return edge.conditionLabel ?? conditionalChoices(node)[index] ?? "";
}

function conditionalChoices(node: WorkflowNode): string[] {
  if (node.config.primitive !== "conditionalFlow") return [];
  if (node.config.branches.length > 0) {
    return node.config.branches.map((branch) => branch.label);
  }
  return node.config.choices;
}

function normalizeLabel(label: string): string {
  return label.trim().toLowerCase();
}
