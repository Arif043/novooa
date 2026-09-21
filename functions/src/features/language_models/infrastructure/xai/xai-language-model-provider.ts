import {
  openAiCompatibleModels,
  type DiscoveredOpenAiCompatibleLanguageModel,
  type NamedLanguageModelProviderConfiguration,
} from "../openai-compatible/named-language-model-provider.js";

const xAiBaseUrl = "https://api.x.ai/v1";

export const xAiLanguageModelProvider: NamedLanguageModelProviderConfiguration = {
  baseUrl: xAiBaseUrl,
  displayName: "xAI (Grok)",
  discoverModels: discoverXAiLanguageModels,
  provider: "xAi",
};

export function discoverXAiLanguageModels(
  value: unknown,
): DiscoveredOpenAiCompatibleLanguageModel[] {
  return openAiCompatibleModels(value);
}
