import {conditionalFlowNodeExecutor} from "../executors/conditional-node-executor.js";
import {humanApprovalNodeExecutor} from "../../../domain/executors/human-approval-node-executor.js";
import {dialogInputNodeExecutor} from "../../../domain/executors/dialog-input-node-executor.js";
import {mediaInputNodeExecutor} from "../../../domain/executors/media-input-node-executor.js";
import {modelInferenceNodeExecutor} from "../../../domain/executors/model-inference-node-executor.js";
import {forEachNodeExecutor} from "../../../domain/executors/for-each-node-executor.js";
import {createGenkitIterativeRefinementNodeExecutor} from "../executors/genkit-iterative-refinement-executor.js";
import {createGenkitPromptNodeExecutor} from "../executors/genkit-prompt-executor.js";
import {readFileNodeExecutor} from "../../../domain/executors/read-file-node-executor.js";
import {
  readChannelEventNodeExecutor,
  readEmailNodeExecutor,
} from "../../../domain/executors/read-email-node-executor.js";
import {createScriptNodeExecutor} from "../../../domain/executors/script-node-executor.js";
import {sendChannelMessageNodeExecutor} from "../executors/send-channel-message-node-executor.js";
import {stringInputNodeExecutor} from "../../../domain/executors/string-input-node-executor.js";
import {writeFileNodeExecutor} from "../executors/write-file-node-executor.js";
import {type WorkflowNode} from "./task-definition.js";
import {type NodeExecutor} from "../../../domain/executors/node-executor.js";
import {type GenkitBeta} from "genkit/beta";
import {type NodeAttachmentWorkspace} from "./node-attachment-workspace.js";
import {createPythonScriptExecutor} from "../../local/python-script-executor.js";
import {logScriptOutput} from "./script-output-logger.js";

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
  if (primitive === "script") {
    return createScriptNodeExecutor(
      createPythonScriptExecutor(workspace),
      logScriptOutput,
    );
  }
  if (primitive === "prompt") return createGenkitPromptNodeExecutor(ai, workspace);
  if (primitive === "iterativeRefinement") {
    return createGenkitIterativeRefinementNodeExecutor(ai, workspace);
  }
  return executors.get(primitive);
}
