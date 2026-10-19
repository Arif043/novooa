import {createConditionalFlowNodeExecutor} from "../../../domain/executors/conditional-node-executor.js";
import {httpRequestNodeExecutor} from "../../../domain/executors/http-request-node-executor.js";
import {humanApprovalNodeExecutor} from "../../../domain/executors/human-approval-node-executor.js";
import {dialogInputNodeExecutor} from "../../../domain/executors/dialog-input-node-executor.js";
import {mediaInputNodeExecutor} from "../../../domain/executors/media-input-node-executor.js";
import {modelInferenceNodeExecutor} from "../../../domain/executors/model-inference-node-executor.js";
import {
  speechToTextNodeExecutor,
  textToSpeechNodeExecutor,
} from "../../../domain/executors/speech-node-executor.js";
import {forEachNodeExecutor} from "../../../domain/executors/for-each-node-executor.js";
import {createGenkitIterativeRefinementNodeExecutor} from "../executors/genkit-iterative-refinement-executor.js";
import {createGenkitPromptNodeExecutor} from "../executors/genkit-prompt-node-executor.js";
import {createTeamworkNodeExecutor} from "../executors/teamwork/teamwork-node-executor.js";
import {readWebhookNodeExecutor} from "../../../domain/executors/read-webhook-node-executor.js";
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
import {tableFromCollectionNodeExecutor} from "../../../domain/executors/table-from-collection-node-executor.js";
import {type WorkflowNode} from "./task-definition.js";
import {type NodeExecutor} from "../../../domain/executors/node-executor.js";
import {type GenkitBeta} from "genkit/beta";
import {type NodeAttachmentWorkspace} from "./node-attachment-workspace.js";
import {type ScriptExecutorFactory} from "../../../domain/executors/script-executor.js";
import {createPythonScriptExecutor} from "../../local/python-script-executor.js";
import {scriptOutputLogger} from "./script-output-logger.js";
import {conditionalBranchLogger} from "./conditional-branch-logger.js";
import {taskMessageLogger} from "./task-message-logger.js";
import {notificationSendLogger} from "./notification-send-logger.js";
import {type GenkitLanguageModelResolver} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../../../language_models/domain/repositories/language-model-defaults-store.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

type Primitive = WorkflowNode["primitive"];

/** Alles, was ein Executor beim Aufbau pro Baustein-Lauf brauchen kann. */
export type NodeExecutorDependencies = {
  ai: GenkitBeta;
  logger: ApplicationLogger;
  workspace?: NodeAttachmentWorkspace;
  languageModelResolver?: GenkitLanguageModelResolver;
  languageModelDefaultsStore?: LanguageModelDefaultsStore;
  scriptExecutorFactory: ScriptExecutorFactory;
};

export type NodeExecutorFactory = (dependencies: NodeExecutorDependencies) => NodeExecutor;

/**
 * Offen für Erweiterung (Plugins, neue Bausteine), geschlossen für Änderungen am Dispatch:
 * Wer einen Executor beisteuert, registriert ihn hier, ohne `task-node-runner.ts` anzufassen.
 */
export class NodeExecutorRegistry {
  private readonly factories = new Map<Primitive, NodeExecutorFactory>();

  /** Für Executoren, die Abhängigkeiten pro Lauf brauchen (Workspace, Modell-Resolver, …). */
  registerFactory(primitive: Primitive, factory: NodeExecutorFactory): this {
    this.factories.set(primitive, factory);
    return this;
  }

  register(executor: NodeExecutor): this {
    return this.registerFactory(executor.primitive, () => executor);
  }

  resolve(primitive: Primitive, dependencies: NodeExecutorDependencies): NodeExecutor | undefined {
    return this.factories.get(primitive)?.(dependencies);
  }
}

export function createDefaultNodeExecutorRegistry(): NodeExecutorRegistry {
  return new NodeExecutorRegistry()
    .registerFactory("script", ({scriptExecutorFactory, workspace, logger}) =>
      createScriptNodeExecutor(scriptExecutorFactory(workspace), scriptOutputLogger(logger)))
    .registerFactory("prompt", ({ai, workspace, languageModelResolver, logger, languageModelDefaultsStore}) =>
      createGenkitPromptNodeExecutor(ai, workspace, languageModelResolver, logger, languageModelDefaultsStore))
    .registerFactory("teamwork", ({ai, workspace, languageModelResolver, logger, languageModelDefaultsStore}) =>
      createTeamworkNodeExecutor({ai, workspace, languageModelResolver, logger, defaultsStore: languageModelDefaultsStore}))
    .registerFactory("iterativeRefinement", ({ai, workspace, logger}) =>
      createGenkitIterativeRefinementNodeExecutor(ai, workspace, logger))
    .registerFactory("conditionalFlow", ({logger}) =>
      createConditionalFlowNodeExecutor(conditionalBranchLogger(logger)))
    .registerFactory("sendChannelMessage", ({logger}) =>
      createSendChannelMessageNodeExecutor(taskMessageLogger(logger)))
    .registerFactory("notificationSend", ({logger}) =>
      createNotificationSendNodeExecutor(notificationSendLogger(logger)))
    .register(httpRequestNodeExecutor)
    .register(stringInputNodeExecutor)
    .register(writeFileNodeExecutor)
    .register(readFileNodeExecutor)
    .register(readEmailNodeExecutor)
    .register(readChannelEventNodeExecutor)
    .register(readWebhookNodeExecutor)
    .register(humanApprovalNodeExecutor)
    .register(dialogInputNodeExecutor)
    .register(mediaInputNodeExecutor)
    .register(modelInferenceNodeExecutor)
    .register(textToSpeechNodeExecutor)
    .register(speechToTextNodeExecutor)
    .register(forEachNodeExecutor)
    .register(documentLookupNodeExecutor)
    .register(saveDocumentNodeExecutor)
    .register(tableFromCollectionNodeExecutor);
}

const defaultRegistry = createDefaultNodeExecutorRegistry();

export function executorFor(
  primitive: Primitive,
  ai: GenkitBeta,
  logger: ApplicationLogger,
  workspace?: NodeAttachmentWorkspace,
  languageModelResolver?: GenkitLanguageModelResolver,
  languageModelDefaultsStore?: LanguageModelDefaultsStore,
  scriptExecutorFactory: ScriptExecutorFactory = createPythonScriptExecutor,
  registry: NodeExecutorRegistry = defaultRegistry,
): NodeExecutor | undefined {
  return registry.resolve(primitive, {
    ai, logger, workspace, languageModelResolver, languageModelDefaultsStore, scriptExecutorFactory,
  });
}
