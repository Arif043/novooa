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
import {type ConditionOperandFailure} from "../entities/condition-operand-failure.js";
import {NodeFailedError} from "../entities/node-execution-failure.js";
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
  if (node.config.primitive !== "conditionalFlow") return {selectedNodeId: null};
  const matchOrFailure = selectConditionedBranch(
    node.config.branches,
    (template) => runContext.templateExpressionResolver.resolveValue(template),
  );
  if (matchOrFailure.isErr()) throw nodeFailedFor(matchOrFailure.error);
  const match = matchOrFailure.value;
  if (!match) return {selectedNodeId: null};
  return {
    selectedNodeId: null,
    selectedBranchId: match.branch.id,
    selectedBranchLabel: match.branch.label,
  };
}

// Executoren melden Fehler laut Vertrag per Exception; Code und Felder der
// Failure reisen darin bis zur Aktivität, wo der Client sie übersetzt.
function nodeFailedFor(failure: ConditionOperandFailure): NodeFailedError {
  return new NodeFailedError({
    code: failure.code,
    message: failure.technicalMessage,
    details: failure.details,
  });
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
