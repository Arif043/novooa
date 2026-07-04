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
  validateGraph(input.taskDefinition);
  const results = await runNodes(ai, input);
  return {
    taskId: input.taskDefinition.id,
    finalOutput: finalOutputOf(results),
    nodeResults: results,
  };
}

async function runNodes(
  ai: Genkit,
  input: RunTaskDefinitionInput,
): Promise<NodeExecutionResult[]> {
  const remaining = [...input.taskDefinition.nodes];
  const results = new Map<string, NodeExecutionResult>();
  const skippedNodeIds = new Set<string>();

  while (remaining.length > 0) {
    const index = nextRunnableIndex(
      remaining,
      input.taskDefinition.edges,
      results,
    );
    if (index === -1) throw new Error("Task graph contains a cycle.");
    const node = remaining.splice(index, 1)[0];
    const context = contextFor(node, input, results);
    const result = shouldSkipNode(
      node,
      input.taskDefinition,
      results,
      skippedNodeIds,
    )
      ? skippedNode(node, "")
      : await executeNode(ai, node, context, input.taskDefinition, results);
    results.set(node.id, result);
    skipInactiveBranches(node, input.taskDefinition, result, skippedNodeIds);
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
          node,
          parentOutputFor(node, task, results),
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

function executeConditional(
  node: WorkflowNode,
  targetLabel: string,
  edges: WorkflowEdge[],
): NodeExecutionResult {
  const output = executeConditionalNode({
    node,
    targetLabel,
    outgoingEdges: edges.filter((edge) => edge.from === node.id),
  });
  return executedNode(node, output.reason, output.selectedNodeId);
}

function parentOutputFor(
  node: WorkflowNode,
  task: Task,
  results: Map<string, NodeExecutionResult>,
): string {
  const parentOutputs = task.edges
    .filter((edge) => edge.to === node.id)
    .map((edge) => results.get(edge.from)?.output ?? "")
    .filter((output) => output.trim().length > 0);
  return parentOutputs[parentOutputs.length - 1] ?? "";
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
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "executed",
    output,
    selectedNodeId,
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
