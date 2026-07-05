import { type Genkit } from "genkit";
import { executeConditionalNode } from "../task-executors/conditional-node-executor.js";
import { executeIterativeRefinementNode } from "../task-executors/iterative-refinement-node-executor.js";
import { executePromptNode } from "../task-executors/prompt-node-executor.js";
import {
  type NodeExecutionResult,
  type RunTaskDefinitionInput,
  type RunTaskDefinitionOutput,
  type TaskDefinition as Task,
  type WorkflowEdge,
  type WorkflowNode,
} from "./task-definition.js";
import {
  contextFor,
  finalOutputOf,
  nextRunnableIndex,
  shouldSkipNode,
  skipInactiveBranches,
  validateGraph,
} from "./task-graph-utils.js";

export async function executeTaskGraph(
  ai: Genkit,
  input: RunTaskDefinitionInput,
): Promise<RunTaskDefinitionOutput> {
  console.log("Task graph execution started.", {
    taskId: input.taskDefinition.id,
    title: input.taskDefinition.title,
    objective: input.taskDefinition.objective,
    context: input.context,
    nodes: input.taskDefinition.nodes,
    edges: input.taskDefinition.edges,
  });
  validateGraph(input.taskDefinition);
  const results = await runNodes(ai, input);
  const output = {
    taskId: input.taskDefinition.id,
    finalOutput: finalOutputOf(results),
    nodeResults: results,
  };
  console.log("Task graph execution finished.", output);
  return output;
}

async function runNodes(
  ai: Genkit,
  input: RunTaskDefinitionInput,
): Promise<NodeExecutionResult[]> {
  const remaining = [...input.taskDefinition.nodes];
  const results = new Map<string, NodeExecutionResult>();
  const skippedNodeIds = new Set<string>();

  while (remaining.length > 0) {
    console.log("Task graph scheduler state.", {
      remainingNodeIds: remaining.map((node) => node.id),
      completedResults: Array.from(results.values()),
      skippedNodeIds: Array.from(skippedNodeIds),
    });
    const index = nextRunnableIndex(
      remaining,
      input.taskDefinition.edges,
      results,
    );
    if (index === -1) throw new Error("Task graph contains a cycle.");
    const node = remaining.splice(index, 1)[0];
    const context = contextFor(node, input, results);
    const skipNode = shouldSkipNode(
      node,
      input.taskDefinition,
      results,
      skippedNodeIds,
    );
    console.log("Task graph selected node.", {
      node,
      context,
      skipNode,
      parentResults: parentResultsFor(node, input.taskDefinition, results),
    });
    const result = skipNode
      ? skippedNode(node, "")
      : await executeNode(ai, node, context, input.taskDefinition, results);
    results.set(node.id, result);
    console.log("Task graph node result.", {
      result,
      resultsSnapshot: Array.from(results.values()),
    });
    skipInactiveBranches(node, input.taskDefinition, result, skippedNodeIds);
    console.log("Task graph branch state.", {
      selectedNodeId: result.selectedNodeId,
      skippedNodeIds: Array.from(skippedNodeIds),
    });
  }

  return input.taskDefinition.nodes.map((node) => results.get(node.id)!);
}

async function executeNode(
  ai: Genkit,
  node: WorkflowNode,
  context: string,
  task: Task,
  results: Map<string, NodeExecutionResult>,
): Promise<NodeExecutionResult> {
  try {
    console.log("####################################");
    console.log("Executing node: ", node);
    console.log("Context: ", context);
    console.log("Task Definition: ", task);
    console.log("####################################");

    switch (node.primitive) {
      case "prompt":
        return executePrompt(ai, node, context);
      case "conditionalFlow":
        return executeConditional(
          ai,
          node,
          parentOutputFor(node, task, results),
          context,
          task,
          task.edges,
        );
      case "iterativeRefinement":
        return executeRefinement(ai, node, context, task.objective);
      default:
        return skippedNode(node, context);
    }
  } catch (error) {
    console.error("Node execution failed.", {
      nodeId: node.id,
      primitive: node.primitive,
      node,
      context,
      taskId: task.id,
      error: errorDetails(error),
    });
    throw error;
  }
}

async function executePrompt(
  ai: Genkit,
  node: WorkflowNode,
  context: string,
): Promise<NodeExecutionResult> {
  const output = await executePromptNode(ai, promptInputFor(node, context));
  return executedNode(node, output.answer);
}

async function executeConditional(
  ai: Genkit,
  node: WorkflowNode,
  targetLabel: string,
  context: string,
  task: Task,
  edges: WorkflowEdge[],
): Promise<NodeExecutionResult> {
  const output = executeConditionalNode({
    node,
    targetLabel,
    outgoingEdges: edges.filter((edge) => edge.from === node.id),
  });
  const branchOutput = await executeSelectedBranch(ai, node, output, context, task);
  return executedNode(node, branchOutput, output.selectedNodeId, {
    selectedBranchId: output.selectedBranchId,
    selectedBranchLabel: output.selectedBranchLabel,
  });
}

async function executeSelectedBranch(
  ai: Genkit,
  node: WorkflowNode,
  output: {
    selectedBranchId?: string | null;
    selectedBranchLabel?: string | null;
    reason: string;
  },
  context: string,
  task: Task,
): Promise<string> {
  const branch = selectedBranchFor(node, output.selectedBranchId);
  if (!branch) return output.reason;
  if (branch.graph.nodes.length === 0) return emptyBranchOutput(output);
  console.log("Executing conditional branch graph.", {
    conditionalNodeId: node.id,
    branchId: branch.id,
    branchLabel: branch.label,
    graph: branch.graph,
  });
  const branchTask = branchTaskFor(task, branch);
  const branchResults = await runNodes(ai, {
    taskDefinition: branchTask,
    context,
  });
  const finalOutput = finalOutputOf(branchResults);
  console.log("Conditional branch graph finished.", {
    conditionalNodeId: node.id,
    branchId: branch.id,
    branchLabel: branch.label,
    finalOutput,
    nodeResults: branchResults,
  });
  return finalOutput || output.reason;
}

function selectedBranchFor(node: WorkflowNode, branchId?: string | null) {
  if (node.config.primitive !== "conditionalFlow") return undefined;
  return node.config.branches.find((branch) => branch.id === branchId);
}

function emptyBranchOutput(output: {selectedBranchLabel?: string | null}) {
  return `Branch ${output.selectedBranchLabel ?? ""} has no nodes.`;
}

function branchTaskFor(task: Task, branch: Branch): Task {
  return {
    id: `${task.id}:${branch.id}`,
    title: `${task.title}:${branch.label}`,
    objective: task.objective,
    nodes: branch.graph.nodes as WorkflowNode[],
    edges: branch.graph.edges,
  };
}

type Branch = Extract<
  WorkflowNode["config"],
  {primitive: "conditionalFlow"}
>["branches"][number];

function parentOutputFor(
  node: WorkflowNode,
  task: Task,
  results: Map<string, NodeExecutionResult>,
): string {
  const parentOutputs = parentResultsFor(node, task, results)
    .map((parentResult) => parentResult.result.output)
    .filter((output) => output.trim().length > 0);
  return parentOutputs[parentOutputs.length - 1] ?? "";
}

function parentResultsFor(
  node: WorkflowNode,
  task: Task,
  results: Map<string, NodeExecutionResult>,
) {
  return task.edges
    .filter((edge) => edge.to === node.id)
    .map((edge) => ({edge, result: results.get(edge.from)}))
    .filter((parent) => parent.result !== undefined) as {
      edge: WorkflowEdge;
      result: NodeExecutionResult;
    }[];
}

async function executeRefinement(
  ai: Genkit,
  node: WorkflowNode,
  context: string,
  objective: string,
): Promise<NodeExecutionResult> {
  const output = await executeIterativeRefinementNode(ai, {
    objective,
    draft: context,
    critiquePrompt: node.description || node.title,
    maxIterations: 2,
  });
  return executedNode(node, output.answer);
}

function promptInputFor(node: WorkflowNode, context: string) {
  const config = promptConfigFor(node);
  return {
    instruction: instructionFor(node),
    context,
    outputType: config?.outputType ?? "text",
    choices: choicesFor(node),
  };
}

function executedNode(
  node: WorkflowNode,
  output: string,
  selectedNodeId?: string | null,
  selection?: {
    selectedBranchId?: string | null;
    selectedBranchLabel?: string | null;
  },
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "executed",
    output,
    selectedNodeId,
    selectedBranchId: selection?.selectedBranchId,
    selectedBranchLabel: selection?.selectedBranchLabel,
  };
}

function skippedNode(node: WorkflowNode, context: string): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "skipped",
    output: context,
    message: "Baustein-Executor ist noch nicht implementiert.",
  };
}

function instructionFor(node: WorkflowNode): string {
  const instruction = promptConfigFor(node)?.instruction.trim();
  if (instruction && instruction.length > 0) return instruction;
  if (node.description.trim().length > 0) return node.description;
  return node.title;
}

function choicesFor(node: WorkflowNode): string[] {
  const config = promptConfigFor(node);
  const choices = config?.choices.length ? config.choices : [
    config?.firstChoice ?? "",
    config?.secondChoice ?? "",
  ];
  return choices.filter((choice) => choice.trim().length > 0);
}

function promptConfigFor(node: WorkflowNode) {
  if (node.config?.primitive !== "prompt") return undefined;
  return node.config;
}

function errorDetails(error: unknown) {
  if (error instanceof Error) {
    return {
      name: error.name,
      message: error.message,
      stack: error.stack,
    };
  }
  return error;
}
