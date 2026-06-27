import {type Genkit} from "genkit";
import {executePromptNode} from "../task-executors/prompt-node-executor.js";
import {
  type NodeExecutionResult,
  type RunTaskDefinitionInput,
  type RunTaskDefinitionOutput,
  type TaskDefinition,
  type WorkflowEdge,
  type WorkflowNode,
} from "./task-definition.js";

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

  while (remaining.length > 0) {
    const index = nextRunnableIndex(remaining, input.taskDefinition.edges, results);
    if (index === -1) throw new Error("Task graph contains a cycle.");
    const node = remaining.splice(index, 1)[0];
    const context = contextFor(node, input, results);
    const result = await executeNode(ai, node, context);
    results.set(node.id, result);
  }

  return input.taskDefinition.nodes.map((node) => results.get(node.id)!);
}

async function executeNode(
  ai: Genkit,
  node: WorkflowNode,
  context: string,
): Promise<NodeExecutionResult> {
  if (node.primitive !== "prompt") return skippedNode(node, context);
  const config = node.promptConfig;
  const output = await executePromptNode(ai, {
    instruction: instructionFor(node),
    context,
    outputType: config?.outputType ?? "text",
    choices: choicesFor(node),
  });
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "executed",
    output: output.answer,
  };
}

function nextRunnableIndex(
  nodes: WorkflowNode[],
  edges: WorkflowEdge[],
  results: Map<string, NodeExecutionResult>,
): number {
  return nodes.findIndex((node) => {
    const parents = edges.filter((edge) => edge.to === node.id);
    return parents.every((edge) => results.has(edge.from));
  });
}

function contextFor(
  node: WorkflowNode,
  input: RunTaskDefinitionInput,
  results: Map<string, NodeExecutionResult>,
): string {
  const parentOutputs = input.taskDefinition.edges
    .filter((edge) => edge.to === node.id)
    .map((edge) => results.get(edge.from)?.output ?? "")
    .filter((output) => output.trim().length > 0);
  return [
    `Aufgabe: ${input.taskDefinition.objective}`,
    input.context,
    ...parentOutputs,
  ]
    .filter((part) => part.trim().length > 0)
    .join("\n\n");
}

function validateGraph(taskDefinition: TaskDefinition): void {
  const nodeIds = new Set<string>();
  for (const node of taskDefinition.nodes) {
    if (nodeIds.has(node.id)) {
      throw new Error(`Task graph contains a duplicate node: ${node.id}.`);
    }
    nodeIds.add(node.id);
  }
  for (const edge of taskDefinition.edges) {
    if (!nodeIds.has(edge.from) || !nodeIds.has(edge.to)) {
      throw new Error(
        `Task graph edge references an unknown node: ${edge.from}->${edge.to}.`,
      );
    }
  }
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

function finalOutputOf(results: NodeExecutionResult[]): string {
  for (let index = results.length - 1; index >= 0; index -= 1) {
    if (results[index].output.trim().length > 0) return results[index].output;
  }
  return "";
}
