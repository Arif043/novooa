import {err, ok, type Result} from "neverthrow";
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
import {type NodeFailure} from "../entities/node-failure.js";
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
      const outputOrFailure = hasExpressionBranches(node)
        ? conditionedOutputFor(node, runContext)
        : ok(labelMatchedOutputFor(node, runContext));
      if (outputOrFailure.isErr()) return err(outputOrFailure.error);
      const output = outputOrFailure.value;
      const branchOutput = await executeSelectedBranch(node, runContext, output, observer);
      return ok(executedNode(node, textOutputs(branchOutput), {
        selectedNodeId: output.selectedNodeId,
        selection: {
          selectedBranchId: output.selectedBranchId,
          selectedBranchLabel: output.selectedBranchLabel,
        },
      }));
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
): Result<ConditionalExecutionResult, NodeFailure> {
  if (node.config.primitive !== "conditionalFlow") return ok({selectedNodeId: null});
  return selectConditionedBranch(
    node.config.branches,
    (template) => runContext.templateExpressionResolver.resolveValue(template),
  ).map((match): ConditionalExecutionResult => match
    ? {selectedNodeId: null, selectedBranchId: match.branch.id, selectedBranchLabel: match.branch.label}
    : {selectedNodeId: null},
  ).mapErr((failure) => failure.toNodeFailure());
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
  if (!branch) return "";
  if (branch.graph.nodes.length === 0) return branch.label;
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
  return finalOutput || branch.label;
}

function selectedBranchFor(node: WorkflowNode, branchId?: string | null) {
  if (node.config.primitive !== "conditionalFlow") return undefined;
  return node.config.branches.find((branch) => branch.id === branchId);
}

function graphFor(branch: Branch["graph"]): import("../entities/task.js").WorkflowGraph {
  return branch as import("../entities/task.js").WorkflowGraph;
}

type Branch = Extract<
  WorkflowNode["config"],
  {primitive: "conditionalFlow"}
>["branches"][number];
