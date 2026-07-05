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
import {
  formatNodeFailed,
  formatNodeHeader,
  formatNodeTrail,
  formatTaskFinished,
  formatTaskStarted,
  errorDetails,
  logError,
  logReadableError,
  logReadableInfo,
} from "./structured-logger.js";

export async function executeTaskGraph(
  ai: Genkit,
  input: RunTaskDefinitionInput,
): Promise<RunTaskDefinitionOutput> {
  logReadableInfo(formatTaskStarted(input.taskDefinition, input.context));
  validateGraph(input.taskDefinition);
  const results = await runNodes(ai, input);
  const output = {
    taskId: input.taskDefinition.id,
    finalOutput: finalOutputOf(results),
    nodeResults: results,
  };
  logReadableInfo(formatTaskFinished(
    output.taskId,
    results.filter((result) => result.status === "executed").length,
    results.filter((result) => result.status === "skipped").length,
    output.finalOutput.length,
  ));
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
    const startedAt = Date.now();
    logNodeHeader(node, input.taskDefinition, context, skipNode, results);
    const result = await runNodeWithTrail(
      ai,
      {node, context, task: input.taskDefinition, results, skipNode, startedAt},
    );
    results.set(node.id, result);
    skipInactiveBranches(node, input.taskDefinition, result, skippedNodeIds);
    logSkippedBranches(node, input.taskDefinition.id, result, skippedNodeIds);
  }

  return input.taskDefinition.nodes.map((node) => results.get(node.id)!);
}

type NodeRunInput = {
  node: WorkflowNode;
  context: string;
  task: Task;
  results: Map<string, NodeExecutionResult>;
  skipNode: boolean;
  startedAt: number;
};

async function runNodeWithTrail(
  ai: Genkit,
  input: NodeRunInput,
): Promise<NodeExecutionResult> {
  try {
    const result = input.skipNode
      ? skippedNode(input.node, "")
      : await executeNode(ai, input.node, input.context, input.task, input.results);
    logNodeTrail(input.task.id, result, input.startedAt);
    return result;
  } catch (error) {
    logNodeErrorTrail(input, error);
    throw error;
  }
}

function logNodeHeader(
  node: WorkflowNode,
  task: Task,
  context: string,
  skipNode: boolean,
  results: Map<string, NodeExecutionResult>,
): void {
  logReadableInfo(formatNodeHeader({
    taskId: task.id,
    node,
    context,
    parentNodeIds: parentResultsFor(node, task, results).map(
      (parent) => parent.result.nodeId,
    ),
    skipNode,
  }));
}

function logNodeTrail(
  taskId: string,
  result: NodeExecutionResult,
  startedAt: number,
): void {
  void taskId;
  logReadableInfo(formatNodeTrail({
    result,
    durationMs: Date.now() - startedAt,
  }));
}

function logNodeErrorTrail(input: NodeRunInput, error: unknown): void {
  logReadableError(formatNodeFailed({
    node: input.node,
    durationMs: Date.now() - input.startedAt,
    error,
  }));
  logError("task_node.exception", {
    taskId: input.task.id,
    nodeId: input.node.id,
    primitive: input.node.primitive,
    title: input.node.title,
    error: errorDetails(error),
  });
}

function logSkippedBranches(
  node: WorkflowNode,
  taskId: string,
  result: NodeExecutionResult,
  skippedNodeIds: Set<string>,
): void {
  if (result.selectedNodeId === undefined) return;
  logReadableInfo([
    `[Verzweigung] ${node.title}`,
    `Aufgabe: ${taskId}`,
    `Gewählt: ${result.selectedBranchLabel ?? result.selectedNodeId ?? "-"}`,
    `Übersprungen: ${Array.from(skippedNodeIds).join(", ") || "-"}`,
  ].join("\n"));
}

async function executeNode(
  ai: Genkit,
  node: WorkflowNode,
  context: string,
  task: Task,
  results: Map<string, NodeExecutionResult>,
): Promise<NodeExecutionResult> {
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
      return executeRefinement(ai, node, context, task);
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
  logReadableInfo([
    `[Zweig startet] ${branch.label}`,
    `Bedingung: ${node.title} (${node.id})`,
    `Bausteine: ${branch.graph.nodes.length} | Kanten: ${branch.graph.edges.length}`,
  ].join("\n"));
  const branchTask = branchTaskFor(task, branch);
  const branchResults = await runNodes(ai, {
    taskDefinition: branchTask,
    context,
  });
  const finalOutput = finalOutputOf(branchResults);
  logReadableInfo([
    `[Zweig beendet] ${branch.label}`,
    `Bausteine ausgeführt: ${branchResults.length}`,
    `Ausgabe: ${finalOutput.length} Zeichen`,
  ].join("\n"));
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
  task: Task,
): Promise<NodeExecutionResult> {
  const config = refinementConfigFor(node);
  const draft = await refinementDraftFor(ai, node, context, task, config);
  const output = await executeIterativeRefinementNode(ai, {
    objective: task.objective,
    draft,
    critiquePrompt: config?.critiquePrompt || node.description || node.title,
    maxIterations: config?.maxIterations ?? 2,
  });
  return executedNode(node, output.answer);
}

async function refinementDraftFor(
  ai: Genkit,
  node: WorkflowNode,
  context: string,
  task: Task,
  config?: RefinementConfig,
): Promise<string> {
  if (!config || config.graph.nodes.length === 0) return context;
  logReadableInfo([
    `[Entwurf startet] ${node.title}`,
    `Aufgabe: ${task.id}`,
    `Bausteine: ${config.graph.nodes.length} | Kanten: ${config.graph.edges.length}`,
  ].join("\n"));
  const draftResults = await runNodes(ai, {
    taskDefinition: refinementTaskFor(task, node, config),
    context,
  });
  const draft = finalOutputOf(draftResults);
  logReadableInfo([
    `[Entwurf beendet] ${node.title}`,
    `Bausteine ausgeführt: ${draftResults.length}`,
    `Entwurf: ${draft.length} Zeichen`,
  ].join("\n"));
  return draft || context;
}

function refinementTaskFor(
  task: Task,
  node: WorkflowNode,
  config: RefinementConfig,
): Task {
  return {
    id: `${task.id}:${node.id}:refinement`,
    title: `${task.title}:${node.title}`,
    objective: task.objective,
    nodes: config.graph.nodes as WorkflowNode[],
    edges: config.graph.edges,
  };
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

function refinementConfigFor(node: WorkflowNode): RefinementConfig | undefined {
  if (node.config?.primitive !== "iterativeRefinement") return undefined;
  return node.config;
}

type RefinementConfig = Extract<
  WorkflowNode["config"],
  {primitive: "iterativeRefinement"}
>;
