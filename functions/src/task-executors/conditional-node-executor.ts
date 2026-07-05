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
  logConditionalInput(input, targetLabel);
  const match = matchingEdgeFor(input, targetLabel);
  const output = conditionalOutputFor(input, match);

  console.log("Conditional node output.", output);
  return output;
}

function conditionalOutputFor(
  input: ConditionalNodeInput,
  match: {edge: WorkflowEdge; label: string} | undefined,
): ConditionalNodeOutput {
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
    const normalizedLabel = normalizeLabel(label);
    const matches = normalizedLabel === targetLabel;
    console.log("Conditional edge candidate.", {
      index,
      edge,
      label,
      normalizedLabel,
      targetLabel,
      matches,
    });
    if (matches) return {edge, label};
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

function logConditionalInput(
  input: ConditionalNodeInput,
  normalizedTargetLabel: string,
): void {
  console.log("Conditional node input.", {
    nodeId: input.node.id,
    primitive: input.node.primitive,
    title: input.node.title,
    config: input.node.config,
    targetLabel: input.targetLabel,
    normalizedTargetLabel,
    outgoingEdges: input.outgoingEdges,
    choices: conditionalChoices(input.node),
  });
}
