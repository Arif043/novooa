import {type WorkflowEdge, type WorkflowNode} from "../runner/task-definition.js";
import {
  type TaskRunContext,
  type NodeExecutor,
  executedNode,
  textForParentOutputs,
  textOutputs,
} from "../runner/node-executor.js";
import {finalOutputOf} from "../runner/task-graph-utils.js";
import {logReadableInfo} from "../runner/structured-logger.js";

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

export const conditionalFlowNodeExecutor: NodeExecutor = {
  primitive: "conditionalFlow",
  async execute(input, runContext) {
    const targetLabel = textForParentOutputs(input.parentOutputs);
    const output = executeConditionalNode({
      node: input.node,
      targetLabel: runContext.resolveTemplates(targetLabel),
      outgoingEdges: runContext.task.edges.filter(
        (edge) => edge.from === input.node.id,
      ),
    });
    const branchOutput = await executeSelectedBranch(input, runContext, output);
    return executedNode(input.node, textOutputs(branchOutput), {
      selectedNodeId: output.selectedNodeId,
      selection: {
        selectedBranchId: output.selectedBranchId,
        selectedBranchLabel: output.selectedBranchLabel,
      },
    });
  },
};

export function executeConditionalNode(
  input: ConditionalNodeInput,
): ConditionalNodeOutput {
  const targetLabel = normalizeLabel(input.targetLabel);
  const branchMatch = matchingBranchFor(input.node, targetLabel);
  const edgeMatch = branchMatch ? undefined : matchingEdgeFor(input, targetLabel);
  const output = conditionalOutputFor(input, branchMatch, edgeMatch);

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
  for (const branch of node.config.branches) {
    const normalizedLabel = normalizeLabel(branch.label);
    if (normalizedLabel === targetLabel) return {branch, matched: true};
  }
  return fallbackBranchFor(node);
}

function fallbackBranchFor(node: WorkflowNode): BranchMatch | undefined {
  if (node.config.primitive !== "conditionalFlow") return undefined;
  const branch = node.config.branches[0];
  if (!branch) return undefined;
  return {branch, matched: false};
}

function matchingEdgeFor(input: ConditionalNodeInput, targetLabel: string) {
  for (const [index, edge] of input.outgoingEdges.entries()) {
    const label = edgeLabel(input.node, edge, index);
    const normalizedLabel = normalizeLabel(label);
    if (normalizedLabel === targetLabel) return {edge, label};
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

async function executeSelectedBranch(
  input: Parameters<NodeExecutor["execute"]>[0],
  runContext: TaskRunContext,
  output: ConditionalNodeOutput,
): Promise<string> {
  const branch = selectedBranchFor(input.node, output.selectedBranchId);
  if (!branch) return output.reason;
  if (branch.graph.nodes.length === 0) return emptyBranchOutput(output);
  logBranchStarted(input.node, branch);
  const branchResults = await runContext.runSubgraph(
    branchTaskFor(runContext.task, branch),
    input.context,
  );
  const finalOutput = finalOutputOf(branchResults);
  logBranchFinished(branch.label, branchResults.length, finalOutput.length);
  return finalOutput || output.reason;
}

function selectedBranchFor(node: WorkflowNode, branchId?: string | null) {
  if (node.config.primitive !== "conditionalFlow") return undefined;
  return node.config.branches.find((branch) => branch.id === branchId);
}

function emptyBranchOutput(output: {selectedBranchLabel?: string | null}) {
  return `Branch ${output.selectedBranchLabel ?? ""} has no nodes.`;
}

function branchTaskFor(task: TaskRunContext["task"], branch: Branch) {
  return {
    id: `${task.id}:${branch.id}`,
    title: `${task.title}:${branch.label}`,
    objective: task.objective,
    nodes: branch.graph.nodes as WorkflowNode[],
    edges: branch.graph.edges,
  };
}

function logBranchStarted(node: WorkflowNode, branch: Branch): void {
  logReadableInfo([
    `[Zweig startet] ${branch.label}`,
    `Bedingung: ${node.title} (${node.id})`,
    `Bausteine: ${branch.graph.nodes.length} | Kanten: ${branch.graph.edges.length}`,
  ].join("\n"));
}

function logBranchFinished(
  branchLabel: string,
  resultCount: number,
  outputLength: number,
): void {
  logReadableInfo([
    `[Zweig beendet] ${branchLabel}`,
    `Bausteine ausgeführt: ${resultCount}`,
    `Ausgabe: ${outputLength} Zeichen`,
  ].join("\n"));
}

type Branch = Extract<
  WorkflowNode["config"],
  {primitive: "conditionalFlow"}
>["branches"][number];
