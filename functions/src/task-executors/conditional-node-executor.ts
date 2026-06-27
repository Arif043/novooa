import {type WorkflowEdge, type WorkflowNode} from "../task-runner/task-definition.js";

export type ConditionalNodeInput = {
  node: WorkflowNode;
  context: string;
  outgoingEdges: WorkflowEdge[];
};

export type ConditionalNodeOutput = {
  selectedNodeId: string | null;
  reason: string;
};

export function executeConditionalNode(
  input: ConditionalNodeInput,
): ConditionalNodeOutput {
  const matchingEdge = input.outgoingEdges.find((edge) => {
    const condition = edge.conditionLabel?.trim();
    if (!condition) return false;
    return input.context.toLowerCase().includes(condition.toLowerCase());
  });

  return {
    selectedNodeId: matchingEdge?.to ?? input.outgoingEdges[0]?.to ?? null,
    reason: matchingEdge
      ? `Matched condition: ${matchingEdge.conditionLabel}`
      : "No condition matched. Used first outgoing branch.",
  };
}
