import {defaultLanguageModelCapabilities} from "../../domain/entities/language-model.js";
import {type DiscoveredOpenAiCompatibleLanguageModel} from "../openai-compatible/named-language-model-provider.js";
import {type ElevenLabsApi} from "./elevenlabs-api.js";

export const elevenLabsDisplayName = "ElevenLabs";

/**
 * ElevenLabs hat keine Chat-API, sondern nur Sprachsynthese: Alle Modelle des
 * Kontos, die Text-to-Speech können, gelten als reine Sprachmodelle.
 */
export async function discoverElevenLabsModels(api: ElevenLabsApi): Promise<DiscoveredOpenAiCompatibleLanguageModel[]> {
  const models = await api.listSpeechModels();
  return models.map((model) => ({
    modelId: model.modelId,
    name: model.name,
    capabilities: defaultLanguageModelCapabilities,
  }));
}
