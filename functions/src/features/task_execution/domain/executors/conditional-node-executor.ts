import {
  executeConditionalFlow,
  type ConditionalExecutionResult,
} from "./conditional-executor.js";
import {selectConditionedBranch} from "./branch-condition-evaluator.js";
import {
  type NodeExecutor,
  executedNode,
  textOutputs,
} from "./node-executor.js";
import {type WorkflowNode} from "../entities/task.js";
import {finalOutputOf} from "../services/task-graph-utils.js";

export type ConditionalBranchObserver = {
  started(event: ConditionalBranchStarted): void;
  finished(event: ConditionalBranchFinished): void;
};

export type ConditionalBranchStarted = {
  node: WorkflowNode;
  branchLabel: string;
  nodeCount: number;
  edgeCount: number;
};

export type ConditionalBranchFinished = {
  branchLabel: string;
  resultCount: number;
  outputLength: number;
};

const noopBranchObserver: ConditionalBranchObserver = {
  started: () => undefined,
  finished: () => undefined,
};

export function createConditionalFlowNodeExecutor(
  observer: ConditionalBranchObserver = noopBranchObserver,
): NodeExecutor {
  return {
    primitive: "conditionalFlow",
    async execute(node, runContext) {
      const output = hasExpressionBranches(node)
        ? conditionedOutputFor(node, runContext)
        : labelMatchedOutputFor(node, runContext);
      const branchOutput = await executeSelectedBranch(
        node,
        runContext,
        output,
        observer,
      );
      return executedNode(node, textOutputs(branchOutput), {
        selectedNodeId: output.selectedNodeId,
        selection: {
          selectedBranchId: output.selectedBranchId,
          selectedBranchLabel: output.selectedBranchLabel,
        },
      });
    },
  };
}

function valueTemplateFor(node: WorkflowNode): string {
  return node.config.primitive === "conditionalFlow"
    ? node.config.valueTemplate ?? ""
    : "";
}

// Trägt irgendein Zweig dieses Knotens ein `condition` (Baukasten-Bedingung
// ohne Entscheidungs-Prompt-Vorgänger), wertet ausschließlich
// `selectConditionedBranch` aus — der bestehende Label-Matching-Pfad bleibt
// für alle anderen Knoten (Entscheidungs-Prompt-getrieben oder Altdaten)
// unverändert, da dort niemals ein `condition` gesetzt ist.
function hasExpressionBranches(node: WorkflowNode): boolean {
  return node.config.primitive === "conditionalFlow" &&
    node.config.branches.some((branch) => branch.condition !== undefined);
}

function conditionedOutputFor(
  node: WorkflowNode,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): ConditionalExecutionResult {
  if (node.config.primitive !== "conditionalFlow") {
    return {selectedNodeId: null, reason: "Kein Bedingter-Ablauf-Baustein."};
  }
  const match = selectConditionedBranch(
    node.config.branches,
    (template) => runContext.templateExpressionResolver.resolveValue(template),
  );
  if (!match) {
    return {
      selectedNodeId: null,
      reason: "Keine Bedingung trifft zu und kein Sonst-Zweig vorhanden.",
    };
  }
  return {
    selectedNodeId: null,
    selectedBranchId: match.branch.id,
    selectedBranchLabel: match.branch.label,
    reason: match.matched
      ? `Bedingung erfüllt: ${match.branch.label}`
      : `Keine Bedingung trifft zu. Sonst-Zweig verwendet: ${match.branch.label}`,
  };
}

function labelMatchedOutputFor(
  node: WorkflowNode,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): ConditionalExecutionResult {
  const targetLabel = runContext.templateExpressionResolver.resolveText(
    valueTemplateFor(node),
  );
  return executeConditionalFlow({
    node,
    targetLabel,
    outgoingEdges: runContext.currentGraph.edges.filter(
      (edge) => edge.from === node.id,
    ),
  });
}

async function executeSelectedBranch(
  node: Parameters<NodeExecutor["execute"]>[0],
  runContext: Parameters<NodeExecutor["execute"]>[1],
  output: ConditionalExecutionResult,
  observer: ConditionalBranchObserver,
): Promise<string> {
  const branch = selectedBranchFor(node, output.selectedBranchId);
  if (!branch) return output.reason;
  if (branch.graph.nodes.length === 0) return emptyBranchOutput(output);
  observer.started({
    node,
    branchLabel: branch.label,
    nodeCount: branch.graph.nodes.length,
    edgeCount: branch.graph.edges.length,
  });
  const results = await runContext.runGraph(
    graphFor(branch.graph),
    runContext.context,
  );
  const finalOutput = finalOutputOf(results);
  observer.finished({
    branchLabel: branch.label,
    resultCount: results.length,
    outputLength: finalOutput.length,
  });
  return finalOutput || output.reason;
}

function selectedBranchFor(node: WorkflowNode, branchId?: string | null) {
  if (node.config.primitive !== "conditionalFlow") return undefined;
  return node.config.branches.find((branch) => branch.id === branchId);
}

function emptyBranchOutput(output: ConditionalExecutionResult): string {
  return `Branch ${output.selectedBranchLabel ?? ""} has no nodes.`;
}

function graphFor(branch: Branch["graph"]): import("../entities/task.js").WorkflowGraph {
  return branch as import("../entities/task.js").WorkflowGraph;
}

type Branch = Extract<
  WorkflowNode["config"],
  {primitive: "conditionalFlow"}
>["branches"][number];
