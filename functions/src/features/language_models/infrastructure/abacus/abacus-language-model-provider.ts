import {defaultLanguageModelCapabilities} from "../../domain/entities/language-model.js";
import {
  openAiCompatibleModels,
  type DiscoveredOpenAiCompatibleLanguageModel,
  type NamedLanguageModelProviderConfiguration,
} from "../openai-compatible/named-language-model-provider.js";

/** Self-Serve-Endpunkt von RouteLLM; Enterprise-Arbeitsbereiche haben eigene Adressen und gehören zum generischen OpenAI-kompatiblen Anbieter. */
const abacusBaseUrl = "https://routellm.abacus.ai/v1";

/** Das Pseudo-Modell, mit dem RouteLLM je Anfrage selbst das passende Modell wählt. */
export const abacusAutomaticRouteModelId = "route-llm";

export const abacusLanguageModelProvider: NamedLanguageModelProviderConfiguration = {
  baseUrl: abacusBaseUrl,
  displayName: "Abacus.AI (RouteLLM)",
  discoverModels: discoverAbacusLanguageModels,
  provider: "abacus",
};

/**
 * `GET /v1/models` liefert die Modelle im OpenAI-Format. Die automatische
 * Modellwahl (`route-llm`) gehört immer dazu und steht zuerst, auch wenn die
 * Liste sie nicht aufführt.
 */
export function discoverAbacusLanguageModels(
  value: unknown,
): DiscoveredOpenAiCompatibleLanguageModel[] {
  const models = openAiCompatibleModels(value);
  const withoutRoute = models.filter((model) => model.modelId !== abacusAutomaticRouteModelId);
  const route = models.find((model) => model.modelId === abacusAutomaticRouteModelId);
  return [
    {
      capabilities: route?.capabilities ?? defaultLanguageModelCapabilities,
      modelId: abacusAutomaticRouteModelId,
      name: "RouteLLM (automatische Modellwahl)",
    },
    ...withoutRoute,
  ];
}
