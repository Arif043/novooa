import {defaultLanguageModelCapabilities} from "../../domain/entities/language-model.js";
import {type DiscoveredOpenAiCompatibleLanguageModel} from "../openai-compatible/named-language-model-provider.js";
import {type ElevenLabsApi} from "./elevenlabs-api.js";

export const elevenLabsDisplayName = "ElevenLabs";

/**
 * ElevenLabs hat keine Chat-API, sondern nur Sprachsynthese: Alle Modelle des
 * Kontos, die Text-to-Speech können, gelten als reine Sprachmodelle.
 */
export async function discoverElevenLabsModels(api: ElevenLabsApi): Promise<DiscoveredOpenAiCompatibleLanguageModel[]> {
  const models = [...await api.listSpeechModels(), ...scribeModels];
  const unique = [...new Map(models.map((model) => [model.modelId, model])).values()];
  return unique.map((model) => ({
    modelId: model.modelId,
    name: model.name,
    capabilities: defaultLanguageModelCapabilities,
  }));
}

/** `models.list` nennt nur Sprachausgabe-Modelle; die Transkriptionsmodelle (Scribe) fehlen dort. */
const scribeModels = [
  {modelId: "scribe_v2", name: "Scribe v2"},
  {modelId: "scribe_v1", name: "Scribe v1"},
];
