import {
  executeConditionalFlow,
  type ConditionalExecutionResult,
} from "./conditional-executor.js";
import {
  type NodeExecutor,
  executedNode,
  textForParentOutputs,
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
    async execute(input, runContext) {
      const targetLabel = runContext.resolveTemplates(
        textForParentOutputs(input.parentOutputs),
      );
      const output = executeConditionalFlow({
        node: input.node,
        targetLabel,
        outgoingEdges: runContext.currentGraph.edges.filter(
          (edge) => edge.from === input.node.id,
        ),
      });
      const branchOutput = await executeSelectedBranch(
        input,
        runContext,
        output,
        observer,
      );
      return executedNode(input.node, textOutputs(branchOutput), {
        selectedNodeId: output.selectedNodeId,
        selection: {
          selectedBranchId: output.selectedBranchId,
          selectedBranchLabel: output.selectedBranchLabel,
        },
      });
    },
  };
}

async function executeSelectedBranch(
  input: Parameters<NodeExecutor["execute"]>[0],
  runContext: Parameters<NodeExecutor["execute"]>[1],
  output: ConditionalExecutionResult,
  observer: ConditionalBranchObserver,
): Promise<string> {
  const branch = selectedBranchFor(input.node, output.selectedBranchId);
  if (!branch) return output.reason;
  if (branch.graph.nodes.length === 0) return emptyBranchOutput(output);
  observer.started({
    node: input.node,
    branchLabel: branch.label,
    nodeCount: branch.graph.nodes.length,
    edgeCount: branch.graph.edges.length,
  });
  const results = await runContext.runGraph(
    graphFor(branch.graph),
    input.context,
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
