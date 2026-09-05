import {conditionalFlowNodeExecutor} from "../executors/conditional-node-executor.js";
import {humanApprovalNodeExecutor} from "../executors/human-approval-node-executor.js";
import {dialogInputNodeExecutor} from "../executors/dialog-input-node-executor.js";
import {mediaInputNodeExecutor} from "../executors/media-input-node-executor.js";
import {modelInferenceNodeExecutor} from "../executors/model-inference-node-executor.js";
import {forEachNodeExecutor} from "../executors/for-each-node-executor.js";
import {createGenkitIterativeRefinementNodeExecutor} from "../executors/genkit-iterative-refinement-executor.js";
import {createGenkitPromptNodeExecutor} from "../executors/genkit-prompt-executor.js";
import {readFileNodeExecutor} from "../executors/read-file-node-executor.js";
import {
  readChannelEventNodeExecutor,
  readEmailNodeExecutor,
} from "../executors/read-email-node-executor.js";
import {createScriptNodeExecutor} from "../executors/script-node-executor.js";
import {sendChannelMessageNodeExecutor} from "../executors/send-channel-message-node-executor.js";
import {stringInputNodeExecutor} from "../executors/string-input-node-executor.js";
import {writeFileNodeExecutor} from "../executors/write-file-node-executor.js";
import {type WorkflowNode} from "./task-definition.js";
import {type NodeExecutor} from "../../../domain/executors/node-executor.js";
import {type GenkitBeta} from "genkit/beta";
import {type NodeAttachmentWorkspace} from "./node-attachment-workspace.js";

const executors = new Map<WorkflowNode["primitive"], NodeExecutor>(
  [
    stringInputNodeExecutor,
    conditionalFlowNodeExecutor,
    writeFileNodeExecutor,
    readFileNodeExecutor,
    readEmailNodeExecutor,
    readChannelEventNodeExecutor,
    sendChannelMessageNodeExecutor,
    humanApprovalNodeExecutor,
    dialogInputNodeExecutor,
    mediaInputNodeExecutor,
    modelInferenceNodeExecutor,
    forEachNodeExecutor,
  ].map((executor) => [executor.primitive, executor]),
);

export function executorFor(
  primitive: WorkflowNode["primitive"],
  ai: GenkitBeta,
  workspace?: NodeAttachmentWorkspace,
): NodeExecutor | undefined {
  if (primitive === "script") return createScriptNodeExecutor(workspace);
  if (primitive === "prompt") return createGenkitPromptNodeExecutor(ai, workspace);
  if (primitive === "iterativeRefinement") {
    return createGenkitIterativeRefinementNodeExecutor(ai, workspace);
  }
  return executors.get(primitive);
}
