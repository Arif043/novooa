import {conditionalFlowNodeExecutor} from "../executors/conditional-node-executor.js";
import {humanApprovalNodeExecutor} from "../executors/human-approval-node-executor.js";
import {iterativeRefinementNodeExecutor} from "../executors/iterative-refinement-node-executor.js";
import {promptNodeExecutor} from "../executors/prompt-node-executor.js";
import {readFileNodeExecutor} from "../executors/read-file-node-executor.js";
import {
  readChannelEventNodeExecutor,
  readEmailNodeExecutor,
} from "../executors/read-email-node-executor.js";
import {scriptNodeExecutor} from "../executors/script-node-executor.js";
import {sendChannelMessageNodeExecutor} from "../executors/send-channel-message-node-executor.js";
import {stringInputNodeExecutor} from "../executors/string-input-node-executor.js";
import {writeFileNodeExecutor} from "../executors/write-file-node-executor.js";
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
    readFileNodeExecutor,
    readEmailNodeExecutor,
    readChannelEventNodeExecutor,
    sendChannelMessageNodeExecutor,
    humanApprovalNodeExecutor,
  ].map((executor) => [executor.primitive, executor]),
);

export function executorFor(
  primitive: WorkflowNode["primitive"],
): NodeExecutor | undefined {
  return executors.get(primitive);
}
