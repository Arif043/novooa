import {conditionalFlowNodeExecutor} from "../task-executors/conditional-node-executor.js";
import {humanApprovalNodeExecutor} from "../task-executors/human-approval-node-executor.js";
import {iterativeRefinementNodeExecutor} from "../task-executors/iterative-refinement-node-executor.js";
import {promptNodeExecutor} from "../task-executors/prompt-node-executor.js";
import {scriptNodeExecutor} from "../task-executors/script-node-executor.js";
import {stringInputNodeExecutor} from "../task-executors/string-input-node-executor.js";
import {writeFileNodeExecutor} from "../task-executors/write-file-node-executor.js";
import {type WorkflowNode} from "./task-definition.js";
import {type NodeExecutor} from "./node-executor.js";

const executors = new Map<WorkflowNode["primitive"], NodeExecutor>(
  [
    stringInputNodeExecutor,
    scriptNodeExecutor,
    promptNodeExecutor,
    conditionalFlowNodeExecutor,
    iterativeRefinementNodeExecutor,
    writeFileNodeExecutor,
    humanApprovalNodeExecutor,
  ].map((executor) => [executor.primitive, executor]),
);

export function executorFor(
  primitive: WorkflowNode["primitive"],
): NodeExecutor | undefined {
  return executors.get(primitive);
}
