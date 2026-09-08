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

export type {PromptNodeInput, PromptNodeOutput, PromptNodeOutputType} from "./prompt-node-types.js";

export function createGenkitPromptExecutor(
  ai: GenkitBeta,
  workspace?: NodeAttachmentWorkspace,
): PromptExecutor {
  return {execute: (request) => executePromptNode(ai, request, workspace)};
}

export function createGenkitPromptNodeExecutor(
  ai: GenkitBeta,
  workspace?: NodeAttachmentWorkspace,
  languageModelResolver?: GenkitLanguageModelResolver,
): NodeExecutor {
  return {
    primitive: "prompt",
    async execute(input, runContext) {
      const promptInput = await promptInputFor(input, runContext);
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
      );
      const outputs = promptInput.outputType === "image"
        ? await persistedImageOutputsFor(output, input.node, runContext)
        : output.outputs;
      return executedNode(input.node, outputs);
    },
  };
}

export function executePromptNode(
  ai: GenkitBeta,
  input: PromptNodeInput,
  workspace?: NodeAttachmentWorkspace,
  languageModel?: ResolvedGenkitLanguageModel,
): Promise<PromptNodeOutput> {
  if (input.outputType === "image") {
    return executeImagePrompt(ai, input, workspace, languageModel);
  }
  if (input.outputType === "decision") {
    return executeDecisionPrompt(ai, input, workspace, languageModel);
  }
  if (input.outputType === "structured") {
    return executeStructuredPrompt(ai, input, workspace, languageModel);
  }
  return executeTextPrompt(ai, input, workspace, languageModel);
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
