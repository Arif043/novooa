import {type PromptExecutor} from "../../../domain/executors/prompt-executor.js";
import {type GenkitBeta} from "genkit/beta";
import {type NodeExecutor, executedNode} from "../../../domain/executors/node-executor.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {executeImagePrompt, persistedImageOutputsFor} from "./prompt-image-executor.js";
import {promptInputFor} from "./prompt-node-input.js";
import {type PromptNodeInput, type PromptNodeOutput} from "./prompt-node-types.js";
import {executeDecisionPrompt, executeStructuredPrompt, executeTextPrompt} from "./prompt-text-executor.js";
import {
  type GenkitLanguageModelResolver,
  type ResolvedGenkitLanguageModel,
} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";
import {FirebaseApplicationLogger} from "../../../../../shared/logging/firebase-application-logger.js";

export type {PromptNodeInput, PromptNodeOutput, PromptNodeOutputType} from "./prompt-node-types.js";

export function createGenkitPromptExecutor(
  ai: GenkitBeta,
  workspace?: NodeAttachmentWorkspace,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
): PromptExecutor {
  return {execute: (request) => executePromptNode(ai, request, workspace, undefined, logger)};
}

export function createGenkitPromptNodeExecutor(
  ai: GenkitBeta,
  workspace?: NodeAttachmentWorkspace,
  languageModelResolver?: GenkitLanguageModelResolver,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
): NodeExecutor {
  return {
    primitive: "prompt",
    async execute(node, runContext) {
      const promptInput = await promptInputFor(node, runContext);
      const languageModel = await languageModelFor(
        promptInput.languageModelId,
        runContext.teamId,
        languageModelResolver,
      );
      validateCapabilities(promptInput, languageModel);
      const output = await executePromptNode(
        languageModel?.ai ?? ai,
        promptInput,
        workspace,
        languageModel,
        logger,
      );
      const outputs = promptInput.outputType === "image"
        ? await persistedImageOutputsFor(output, node, runContext)
        : output.outputs;
      return executedNode(node, outputs);
    },
  };
}

export function executePromptNode(
  ai: GenkitBeta,
  input: PromptNodeInput,
  workspace?: NodeAttachmentWorkspace,
  languageModel?: ResolvedGenkitLanguageModel,
  logger: ApplicationLogger = new FirebaseApplicationLogger(),
): Promise<PromptNodeOutput> {
  if (input.outputType === "image") {
    return executeImagePrompt(ai, input, workspace, languageModel, logger);
  }
  if (input.outputType === "decision") {
    return executeDecisionPrompt(ai, input, workspace, languageModel, logger);
  }
  if (input.outputType === "structured") {
    return executeStructuredPrompt(ai, input, workspace, languageModel, logger);
  }
  return executeTextPrompt(ai, input, workspace, languageModel, logger);
}

async function languageModelFor(
  languageModelId: string | undefined,
  teamId: string,
  resolver: GenkitLanguageModelResolver | undefined,
): Promise<ResolvedGenkitLanguageModel | undefined> {
  if (!languageModelId || languageModelId.trim().length === 0) return undefined;
  if (!resolver) throw new Error("Die Sprachmodell-Auswahl ist nicht konfiguriert.");
  return resolver.resolve(teamId, languageModelId);
}

function validateCapabilities(
  input: PromptNodeInput,
  languageModel: ResolvedGenkitLanguageModel | undefined,
): void {
  if (!languageModel) return;
  const capabilities = languageModel.capabilities;
  if (!capabilities.textGeneration) {
    throw new Error("Das gewählte Sprachmodell unterstützt keine Textgenerierung.");
  }
  if (input.mediaUrls.length > 0 && !capabilities.imageInput) {
    throw new Error("Das gewählte Sprachmodell unterstützt keine Bildeingaben.");
  }
  if (input.outputType === "structured" && !capabilities.structuredOutput) {
    throw new Error("Das gewählte Sprachmodell unterstützt keine strukturierte Ausgabe.");
  }
  if (input.outputType === "image" && !capabilities.imageGeneration) {
    throw new Error("Das gewählte Sprachmodell unterstützt keine Bildgenerierung.");
  }
}
