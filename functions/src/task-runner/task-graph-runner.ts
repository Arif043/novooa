import { type Genkit } from "genkit";
import { executeConditionalNode } from "../task-executors/conditional-node-executor.js";
import { executeIterativeRefinementNode } from "../task-executors/iterative-refinement-node-executor.js";
import { executePromptNode } from "../task-executors/prompt-node-executor.js";
import {
  type NodeExecutionResult,
  type RunTaskDefinitionInput,
  type RunTaskDefinitionOutput,
  type TaskDefinition,
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
      : await executeNode(ai, node, context, input.taskDefinition);
    results.set(node.id, result);
    skipInactiveBranches(node, input.taskDefinition, result, skippedNodeIds);
  }

  return input.taskDefinition.nodes.map((node) => results.get(node.id)!);
}

async function executeNode(
  ai: Genkit,
  node: WorkflowNode,
  context: string,
  taskDefinition: TaskDefinition,
): Promise<NodeExecutionResult> {

  console.log("####################################")
  console.log("Executing node: ", node)
  console.log("Context: ", context)
  console.log("Task Definition: ", taskDefinition)
  console.log("####################################")

  switch (node.primitive) {
    case "prompt":
      return executePrompt(ai, node, context);
    case "conditionalFlow":
      return executeConditional(node, context, taskDefinition.edges);
    case "iterativeRefinement":
      return executeRefinement(ai, node, context, taskDefinition.objective);
    default:
      return skippedNode(node, context);
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
  context: string,
  edges: WorkflowEdge[],
): NodeExecutionResult {
  const output = executeConditionalNode({
    node,
    context,
    outgoingEdges: edges.filter((edge) => edge.from === node.id),
  });
  return executedNode(node, output.reason, output.selectedNodeId);
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
  const config = node.promptConfig;
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
  const instruction = node.promptConfig?.instruction.trim();
  if (instruction && instruction.length > 0) return instruction;
  if (node.description.trim().length > 0) return node.description;
  return node.title;
}

function choicesFor(node: WorkflowNode): string[] {
  return [
    node.promptConfig?.firstChoice ?? "",
    node.promptConfig?.secondChoice ?? "",
  ].filter((choice) => choice.trim().length > 0);
}
