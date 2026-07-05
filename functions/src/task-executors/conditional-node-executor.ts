import {type WorkflowEdge, type WorkflowNode} from "../task-runner/task-definition.js";

export type ConditionalNodeInput = {
  node: WorkflowNode;
  targetLabel: string;
  outgoingEdges: WorkflowEdge[];
};

export type ConditionalNodeOutput = {
  selectedNodeId: string | null;
  selectedBranchId?: string | null;
  selectedBranchLabel?: string | null;
  reason: string;
};

export function executeConditionalNode(
  input: ConditionalNodeInput,
): ConditionalNodeOutput {
  const targetLabel = normalizeLabel(input.targetLabel);
  logConditionalInput(input, targetLabel);
  const branchMatch = matchingBranchFor(input.node, targetLabel);
  const edgeMatch = branchMatch ? undefined : matchingEdgeFor(input, targetLabel);
  const output = conditionalOutputFor(input, branchMatch, edgeMatch);

  console.log("Conditional node output.", output);
  return output;
}

function conditionalOutputFor(
  input: ConditionalNodeInput,
  branchMatch: BranchMatch | undefined,
  edgeMatch: EdgeMatch | undefined,
): ConditionalNodeOutput {
  if (branchMatch) {
    return {
      selectedNodeId: null,
      selectedBranchId: branchMatch.branch.id,
      selectedBranchLabel: branchMatch.branch.label,
      reason: branchMatch.matched
        ? `Matched branch label: ${branchMatch.branch.label}`
        : `No target label matched: ${input.targetLabel}. Used first branch.`,
    };
  }
  return {
    selectedNodeId: edgeMatch?.edge.to ?? input.outgoingEdges[0]?.to ?? null,
    reason: edgeMatch
      ? `Matched target label: ${edgeMatch.label}`
      : `No target label matched: ${input.targetLabel}. Used first branch.`,
  };
}

type BranchMatch = {
  branch: {id: string; label: string};
  matched: boolean;
};

type EdgeMatch = {
  edge: WorkflowEdge;
  label: string;
};

function matchingBranchFor(
  node: WorkflowNode,
  targetLabel: string,
): BranchMatch | undefined {
  if (node.config.primitive !== "conditionalFlow") return undefined;
  for (const [index, branch] of node.config.branches.entries()) {
    const normalizedLabel = normalizeLabel(branch.label);
    const matches = normalizedLabel === targetLabel;
    console.log("Conditional branch candidate.", {
      index,
      branchId: branch.id,
      label: branch.label,
      normalizedLabel,
      targetLabel,
      nodeCount: branch.graph.nodes.length,
      edgeCount: branch.graph.edges.length,
      matches,
    });
    if (matches) return {branch, matched: true};
  }
  return fallbackBranchFor(node);
}

function fallbackBranchFor(node: WorkflowNode): BranchMatch | undefined {
  if (node.config.primitive !== "conditionalFlow") return undefined;
  const branch = node.config.branches[0];
  if (!branch) return undefined;
  console.log("Conditional branch fallback selected.", {
    branchId: branch.id,
    label: branch.label,
  });
  return {branch, matched: false};
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
