import {
  type NodeExecutionResult,
  type NodeOutputValue,
  type WorkflowGraph,
  type TaskGraphInput,
  type TaskGraphOutput,
  type TaskResumeState,
  type WorkflowNode,
} from "./task-definition.js";
import {finalOutputOf} from "../../../domain/services/task-graph-utils.js";
import {type FailedNode, NodeExecutionFailure} from "../../../domain/entities/node-execution-failure.js";
import {NodeFailure} from "../../../domain/entities/node-failure.js";

export type InitialNodeRunState = {
  nodeResults: NodeExecutionResult[];
  remainingNodeIds: string[];
  skippedNodeIds: string[];
};

export type NodeRunState = {
  status: "completed";
  nodeResults: NodeExecutionResult[];
} | ({
  status: "waitingForApproval";
} & TaskResumeState);

export function orderedResults(
  graph: WorkflowGraph,
  results: Map<string, NodeExecutionResult>,
): NodeExecutionResult[] {
  return graph.nodes
    .map((node) => results.get(node.id))
    .filter((result): result is NodeExecutionResult => result !== undefined);
}

export function pausedOutput(
  input: TaskGraphInput,
  state: Extract<NodeRunState, {status: "waitingForApproval"}>,
): TaskGraphOutput {
  return {
    status: "waitingForApproval",
    taskId: input.taskDefinition.id,
    finalOutput: finalOutputOf(state.nodeResults),
    nodeResults: state.nodeResults,
    resumeState: resumeStateFrom(state),
  };
}

export function completedOutput(
  input: TaskGraphInput,
  results: NodeExecutionResult[],
): TaskGraphOutput {
  return {
    status: "completed",
    taskId: input.taskDefinition.id,
    finalOutput: finalOutputOf(results),
    nodeResults: results,
  };
}

export function resumedState(
  state: TaskResumeState,
  responseOutputs: Record<string, NodeOutputValue>,
): InitialNodeRunState {
  return {
    nodeResults: state.nodeResults.map((result) =>
      result.nodeId === state.waitingNodeId
        ? {
          ...result,
          status: "executed",
          outputs: responseOutputs,
          interaction: undefined,
          dialogInput: undefined,
        }
        : result,
    ),
    remainingNodeIds: state.remainingNodeIds,
    skippedNodeIds: state.skippedNodeIds,
  };
}

export function remainingNodes(
  graph: WorkflowGraph,
  state?: InitialNodeRunState,
): WorkflowNode[] {
  if (!state) return [...graph.nodes];
  const remainingIds = new Set(state.remainingNodeIds);
  return graph.nodes.filter((node) => remainingIds.has(node.id));
}

export function resultsMapFrom(results: NodeExecutionResult[]) {
  return new Map(results.map((result) => [result.nodeId, result]));
}

function resumeStateFrom(
  state: Extract<NodeRunState, {status: "waitingForApproval"}>,
): TaskResumeState {
  return {
    nodeResults: state.nodeResults,
    remainingNodeIds: state.remainingNodeIds,
    skippedNodeIds: state.skippedNodeIds,
    waitingNodeId: state.waitingNodeId,
  };
}

/** Die Ergebnisse, die dieser Lauf selbst erzeugt hat; was aus einer früheren Freigabe stammt, steht schon in den Aktivitäten. */
export function newResults(
  graph: WorkflowGraph,
  results: Map<string, NodeExecutionResult>,
  initialState?: InitialNodeRunState,
): NodeExecutionResult[] {
  const alreadyRecorded = new Set((initialState?.nodeResults ?? []).map((result) => result.nodeId));
  return orderedResults(graph, results).filter((result) => !alreadyRecorded.has(result.nodeId));
}

/** Ein Baustein hat eine Failure als Wert geliefert. */
export function failedNodeExecution(node: WorkflowNode, failure: NodeFailure, completed: NodeExecutionResult[]): NodeExecutionFailure {
  return new NodeExecutionFailure(failedNodeFor(node, failure.message, failure, failure.console), completed, failure);
}

/** Ein Baustein oder die Infrastruktur hat geworfen: ein gescheiterter Baustein ohne Code. */
export function nodeExecutionFailure(node: WorkflowNode, error: unknown, completed: NodeExecutionResult[]): NodeExecutionFailure {
  const message = error instanceof Error ? error.message : String(error);
  return new NodeExecutionFailure(failedNodeFor(node, message), completed, error);
}

function failedNodeFor(node: WorkflowNode, message: string, failure?: NodeFailure, console?: FailedNode["console"]): FailedNode {
  return {
    nodeId: node.id, primitive: node.primitive, message, console,
    ...(failure ? {failureCode: failure.code} : {}),
    ...(failure && Object.keys(failure.details).length > 0 ? {failureDetails: {...failure.details}} : {}),
  };
}
