import {createConditionalFlowNodeExecutor} from "../../../domain/executors/conditional-node-executor.js";
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
import {createSendChannelMessageNodeExecutor} from "../../../domain/executors/send-channel-message-node-executor.js";
import {createNotificationSendNodeExecutor} from "../../../domain/executors/notification-send-node-executor.js";
import {stringInputNodeExecutor} from "../../../domain/executors/string-input-node-executor.js";
import {writeFileNodeExecutor} from "../../../domain/executors/write-file-node-executor.js";
import {documentLookupNodeExecutor} from "../../../domain/executors/document-lookup-node-executor.js";
import {saveDocumentNodeExecutor} from "../../../domain/executors/save-document-node-executor.js";
import {type WorkflowNode} from "./task-definition.js";
import {type NodeExecutor} from "../../../domain/executors/node-executor.js";
import {type GenkitBeta} from "genkit/beta";
import {type NodeAttachmentWorkspace} from "./node-attachment-workspace.js";
import {createPythonScriptExecutor} from "../../local/python-script-executor.js";
import {scriptOutputLogger} from "./script-output-logger.js";
import {conditionalBranchLogger} from "./conditional-branch-logger.js";
import {taskMessageLogger} from "./task-message-logger.js";
import {notificationSendLogger} from "./notification-send-logger.js";
import {type GenkitLanguageModelResolver} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

function executorsFor(logger: ApplicationLogger) {
  return new Map<WorkflowNode["primitive"], NodeExecutor>([
    stringInputNodeExecutor,
    createConditionalFlowNodeExecutor(conditionalBranchLogger(logger)),
    writeFileNodeExecutor,
    readFileNodeExecutor,
    readEmailNodeExecutor,
    readChannelEventNodeExecutor,
    createSendChannelMessageNodeExecutor(taskMessageLogger(logger)),
    createNotificationSendNodeExecutor(notificationSendLogger(logger)),
    humanApprovalNodeExecutor,
    dialogInputNodeExecutor,
    mediaInputNodeExecutor,
    modelInferenceNodeExecutor,
    forEachNodeExecutor,
    documentLookupNodeExecutor,
    saveDocumentNodeExecutor,
  ].map((executor) => [executor.primitive, executor]));
}

export function executorFor(
  primitive: WorkflowNode["primitive"],
  ai: GenkitBeta,
  logger: ApplicationLogger,
  workspace?: NodeAttachmentWorkspace,
  languageModelResolver?: GenkitLanguageModelResolver,
): NodeExecutor | undefined {
  if (primitive === "script") {
    return createScriptNodeExecutor(
      createPythonScriptExecutor(workspace),
      scriptOutputLogger(logger),
    );
  }
  if (primitive === "prompt") {
    return createGenkitPromptNodeExecutor(ai, workspace, languageModelResolver, logger);
  }
  if (primitive === "iterativeRefinement") {
    return createGenkitIterativeRefinementNodeExecutor(ai, workspace, logger);
  }
  return executorsFor(logger).get(primitive);
}
