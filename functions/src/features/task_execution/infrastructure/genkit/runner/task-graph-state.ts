import {
  type NodeExecutionResult,
  type TaskDefinition as Task,
  type TaskGraphInput,
  type TaskGraphOutput,
  type TaskResumeState,
  type WorkflowNode,
} from "./task-definition.js";
import {finalOutputOf} from "./task-graph-utils.js";
import {type TaskVariables} from "./node-executor.js";

export type InitialNodeRunState = {
  nodeResults: NodeExecutionResult[];
  variables: TaskVariables;
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
  task: Task,
  results: Map<string, NodeExecutionResult>,
): NodeExecutionResult[] {
  return task.nodes
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
  approvedOutput: string,
): InitialNodeRunState {
  return {
    nodeResults: state.nodeResults.map((result) =>
      result.nodeId === state.waitingNodeId
        ? {
          ...result,
          status: "executed",
          outputs: {text: {type: "string", value: approvedOutput}},
        }
        : result,
    ),
    variables: state.variables,
    remainingNodeIds: state.remainingNodeIds,
    skippedNodeIds: state.skippedNodeIds,
  };
}

export function remainingNodes(
  task: Task,
  state?: InitialNodeRunState,
): WorkflowNode[] {
  if (!state) return [...task.nodes];
  const remainingIds = new Set(state.remainingNodeIds);
  return task.nodes.filter((node) => remainingIds.has(node.id));
}

export function resultsMapFrom(results: NodeExecutionResult[]) {
  return new Map(results.map((result) => [result.nodeId, result]));
}

function resumeStateFrom(
  state: Extract<NodeRunState, {status: "waitingForApproval"}>,
): TaskResumeState {
  return {
    nodeResults: state.nodeResults,
    variables: state.variables,
    remainingNodeIds: state.remainingNodeIds,
    skippedNodeIds: state.skippedNodeIds,
    waitingNodeId: state.waitingNodeId,
  };
}
