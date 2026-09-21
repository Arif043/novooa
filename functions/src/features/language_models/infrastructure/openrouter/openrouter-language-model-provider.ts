import {
  openAiCompatibleModels,
  type DiscoveredOpenAiCompatibleLanguageModel,
  type NamedLanguageModelProviderConfiguration,
} from "../openai-compatible/named-language-model-provider.js";

const openRouterBaseUrl = "https://openrouter.ai/api/v1";

export const openRouterLanguageModelProvider: NamedLanguageModelProviderConfiguration = {
  baseUrl: openRouterBaseUrl,
  displayName: "OpenRouter",
  discoverModels: discoverOpenRouterLanguageModels,
  provider: "openRouter",
};

export function discoverOpenRouterLanguageModels(
  value: unknown,
): DiscoveredOpenAiCompatibleLanguageModel[] {
  return openAiCompatibleModels(value);
}
