import {type GenkitBeta} from "genkit/beta";
import {ResultAsync} from "neverthrow";
import {type PromptExecutor} from "../../../domain/executors/prompt-executor.js";
import {type NodeAttachmentWorkspace} from "../runner/node-attachment-workspace.js";
import {imageModel, imageModelLogContext, modelLogContext, textModel, textModelGenerationConfig} from "../runner/ai-models.js";
import {executeImagePrompt} from "./prompt-image-executor.js";
import {languageModelFor, validateCapabilities} from "./prompt-language-model.js";
import {type PromptModelCall} from "./prompt-model-call.js";
import {type PromptNodeInput, type PromptNodeOutput} from "./prompt-node-types.js";
import {executeDecisionPrompt, executeStructuredPrompt, executeTextPrompt} from "./prompt-text-executor.js";
import {
  type GenkitLanguageModelResolver,
  type ResolvedGenkitLanguageModel,
} from "../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {type LanguageModelDefaultsStore} from "../../../../language_models/domain/repositories/language-model-defaults-store.js";
import {type LanguageModelFailure} from "../../../../language_models/domain/entities/language-model-failure.js";
import {languageModelFailureFrom} from "../../../../language_models/infrastructure/errors/language-model-failure-mapper.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";
import {FirebaseApplicationLogger} from "../../../../../shared/logging/firebase-application-logger.js";

export type {PromptNodeInput, PromptNodeOutput, PromptNodeOutputType} from "./prompt-node-types.js";
export {languageModelFor} from "./prompt-language-model.js";

export type GenkitPromptExecutorDependencies = {
  ai: GenkitBeta;
  workspace?: NodeAttachmentWorkspace;
  languageModelResolver?: GenkitLanguageModelResolver;
  defaultsStore?: LanguageModelDefaultsStore;
  logger?: ApplicationLogger;
};

/**
 * Führt Prompts über Genkit aus. An dieser Grenze werden unsere Exceptions (Framework-Fehler sind
 * vorher übersetzt) zu einer `LanguageModelFailure`.
 */
export class GenkitPromptExecutor implements PromptExecutor {
  private readonly logger: ApplicationLogger;

  constructor(private readonly dependencies: GenkitPromptExecutorDependencies) {
    this.logger = dependencies.logger ?? new FirebaseApplicationLogger();
  }

  execute(request: PromptNodeInput): ResultAsync<PromptNodeOutput, LanguageModelFailure> {
    return ResultAsync.fromPromise(this.run(request), languageModelFailureFrom);
  }

  private async run(request: PromptNodeInput): Promise<PromptNodeOutput> {
    const {languageModelResolver, defaultsStore} = this.dependencies;
    const languageModel = await languageModelFor(
      request.languageModelId, request.teamId, languageModelResolver, defaultsStore,
    );
    validateCapabilities(request, languageModel);
    return executePromptNode(this.callFor(request, languageModel), request);
  }

  private callFor(request: PromptNodeInput, languageModel: ResolvedGenkitLanguageModel | undefined): PromptModelCall {
    const {ai, workspace} = this.dependencies;
    const base = {ai: languageModel?.ai ?? ai, workspace, logger: this.logger};
    if (languageModel) {
      const config = languageModel.generationConfig.configFor(request.generationOptions);
      return {...base, model: languageModel.model, config, logContext: languageModel.logContext};
    }
    if (request.outputType === "image") {
      return {...base, model: imageModel(), config: {}, logContext: imageModelLogContext()};
    }
    const config = textModelGenerationConfig().configFor(request.generationOptions);
    return {...base, model: textModel(), config, logContext: modelLogContext()};
  }
}

export function executePromptNode(call: PromptModelCall, input: PromptNodeInput): Promise<PromptNodeOutput> {
  switch (input.outputType) {
    case "image": return executeImagePrompt(call, input);
    case "decision": return executeDecisionPrompt(call, input);
    case "structured": return executeStructuredPrompt(call, input);
    default: return executeTextPrompt(call, input);
  }
}
