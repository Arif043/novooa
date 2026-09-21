import {
  openAiCompatibleModels,
  type DiscoveredOpenAiCompatibleLanguageModel,
  type NamedLanguageModelProviderConfiguration,
} from "../openai-compatible/named-language-model-provider.js";

const mistralBaseUrl = "https://api.mistral.ai/v1";

export const mistralLanguageModelProvider: NamedLanguageModelProviderConfiguration = {
  baseUrl: mistralBaseUrl,
  displayName: "Mistral AI",
  discoverModels: discoverMistralLanguageModels,
  provider: "mistral",
};

export function discoverMistralLanguageModels(
  value: unknown,
): DiscoveredOpenAiCompatibleLanguageModel[] {
  return openAiCompatibleModels(value);
}
