import {conditionalFlowNodeExecutor} from "../task-executors/conditional-node-executor.js";
import {iterativeRefinementNodeExecutor} from "../task-executors/iterative-refinement-node-executor.js";
import {promptNodeExecutor} from "../task-executors/prompt-node-executor.js";
import {stringInputNodeExecutor} from "../task-executors/string-input-node-executor.js";
import {type WorkflowNode} from "./task-definition.js";
import {type NodeExecutor} from "./node-executor.js";

const executors = new Map<WorkflowNode["primitive"], NodeExecutor>(
  [
    stringInputNodeExecutor,
    promptNodeExecutor,
    conditionalFlowNodeExecutor,
    iterativeRefinementNodeExecutor,
  ].map((executor) => [executor.primitive, executor]),
);

export function executorFor(
  primitive: WorkflowNode["primitive"],
): NodeExecutor | undefined {
  return executors.get(primitive);
}
