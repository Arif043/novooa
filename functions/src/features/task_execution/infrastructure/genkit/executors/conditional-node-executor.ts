import {
  executeConditionalFlow,
  type ConditionalExecutionResult,
} from "../../../domain/executors/conditional-executor.js";
import {
  type NodeExecutor,
  executedNode,
  textForParentOutputs,
  textOutputs,
} from "../../../domain/executors/node-executor.js";
import {type WorkflowNode} from "../../../domain/entities/task.js";
import {finalOutputOf} from "../runner/task-graph-utils.js";
import {logReadableInfo} from "../runner/structured-logger.js";

export const conditionalFlowNodeExecutor: NodeExecutor = {
  primitive: "conditionalFlow",
  async execute(input, runContext) {
    const targetLabel = runContext.resolveTemplates(
      textForParentOutputs(input.parentOutputs),
    );
    const output = executeConditionalFlow({
      node: input.node,
      targetLabel,
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

async function executeSelectedBranch(
  input: Parameters<NodeExecutor["execute"]>[0],
  runContext: Parameters<NodeExecutor["execute"]>[1],
  output: ConditionalExecutionResult,
): Promise<string> {
  const branch = selectedBranchFor(input.node, output.selectedBranchId);
  if (!branch) return output.reason;
  if (branch.graph.nodes.length === 0) return emptyBranchOutput(output);
  logBranchStarted(input.node, branch);
  const results = await runContext.runSubgraph(
    branchTaskFor(runContext.task, branch),
    input.context,
  );
  const finalOutput = finalOutputOf(results);
  logBranchFinished(branch.label, results.length, finalOutput.length);
  return finalOutput || output.reason;
}

function selectedBranchFor(node: WorkflowNode, branchId?: string | null) {
  if (node.config.primitive !== "conditionalFlow") return undefined;
  return node.config.branches.find((branch) => branch.id === branchId);
}

function emptyBranchOutput(output: ConditionalExecutionResult): string {
  return `Branch ${output.selectedBranchLabel ?? ""} has no nodes.`;
}

function branchTaskFor(
  task: Parameters<NodeExecutor["execute"]>[1]["task"],
  branch: Branch,
) {
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
