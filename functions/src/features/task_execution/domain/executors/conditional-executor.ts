import {type WorkflowEdge, type WorkflowNode} from "../entities/task.js";

export type ConditionalExecutionRequest = {
  node: WorkflowNode;
  targetLabel: string;
  outgoingEdges: WorkflowEdge[];
};

export type ConditionalExecutionResult = {
  selectedNodeId: string | null;
  selectedBranchId?: string | null;
  selectedBranchLabel?: string | null;
};

export function executeConditionalFlow(
  input: ConditionalExecutionRequest,
): ConditionalExecutionResult {
  const targetLabel = normalizeLabel(input.targetLabel);
  const branchMatch = matchingBranchFor(input.node, targetLabel);
  const edgeMatch = branchMatch ? undefined : matchingEdgeFor(input, targetLabel);
  return conditionalOutputFor(input, branchMatch, edgeMatch);
}

function conditionalOutputFor(
  input: ConditionalExecutionRequest,
  branchMatch: BranchMatch | undefined,
  edgeMatch: EdgeMatch | undefined,
): ConditionalExecutionResult {
  if (branchMatch) {
    return {
      selectedNodeId: null,
      selectedBranchId: branchMatch.branch.id,
      selectedBranchLabel: branchMatch.branch.label,
    };
  }
  return {
    selectedNodeId: edgeMatch?.edge.to ?? input.outgoingEdges[0]?.to ?? null,
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
  for (const branch of node.config.branches) {
    if (normalizeLabel(branch.label) === targetLabel) {
      return {branch, matched: true};
    }
  }
  const branch = node.config.branches[0];
  return branch ? {branch, matched: false} : undefined;
}

function matchingEdgeFor(
  input: ConditionalExecutionRequest,
  targetLabel: string,
): EdgeMatch | undefined {
  for (const [index, edge] of input.outgoingEdges.entries()) {
    const label = edge.conditionLabel ?? conditionalChoices(input.node)[index] ?? "";
    if (normalizeLabel(label) === targetLabel) return {edge, label};
  }
  return undefined;
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
