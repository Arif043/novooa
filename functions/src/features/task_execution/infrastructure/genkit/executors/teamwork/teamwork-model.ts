import {type ModelArgument} from "genkit";
import {type GenkitBeta} from "genkit/beta";
import {type GenerationOptions} from "../../../../../language_models/domain/entities/generation-options.js";
import {type LanguageModelDefaultsStore} from "../../../../../language_models/domain/repositories/language-model-defaults-store.js";
import {type GenkitLanguageModelResolver} from "../../../../../language_models/infrastructure/genkit/genkit-language-model-resolver.js";
import {modelLogContext, textModel, textModelGenerationConfig} from "../../runner/ai-models.js";
import {languageModelFor} from "../prompt-language-model.js";

/** Ein aufgelöstes Modell samt der Genkit-Instanz, in der es registriert ist. */
export type TeamworkModel = {
  ai: GenkitBeta;
  model: ModelArgument;
  config: Record<string, unknown>;
  logContext: unknown;
};

export type TeamworkModelSources = {
  ai: GenkitBeta;
  languageModelResolver?: GenkitLanguageModelResolver;
  defaultsStore?: LanguageModelDefaultsStore;
};

/**
 * Löst das Modell eines Agenten auf, mit derselben Rückfallkette wie beim Prompt-Baustein. Fähigkeiten
 * werden nicht vorab geprüft: Was ein Modell nicht kann, lehnt der Anbieter ab (`capabilityMissing`).
 */
export async function teamworkModelFor(
  request: {languageModelId?: string; teamId: string; generationOptions: GenerationOptions},
  sources: TeamworkModelSources,
): Promise<TeamworkModel> {
  const resolved = await languageModelFor(
    request.languageModelId, request.teamId, sources.languageModelResolver, sources.defaultsStore,
  );
  if (!resolved) {
    const config = textModelGenerationConfig().configFor(request.generationOptions);
    return {ai: sources.ai, model: textModel(), config, logContext: modelLogContext()};
  }
  const config = resolved.generationConfig.configFor(request.generationOptions);
  return {ai: resolved.ai, model: resolved.model, config, logContext: resolved.logContext};
}
