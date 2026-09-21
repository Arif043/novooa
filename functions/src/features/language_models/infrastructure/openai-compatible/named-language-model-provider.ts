import {
  defaultLanguageModelCapabilities,
  type LanguageModelCapabilities,
  type LanguageModelProvider,
} from "../../domain/entities/language-model.js";

export type NamedOpenAiCompatibleLanguageModelProvider = Exclude<
  LanguageModelProvider,
  "googleAi" | "ollama" | "openAiCompatible"
>;

export type DiscoveredOpenAiCompatibleLanguageModel = {
  capabilities: LanguageModelCapabilities;
  modelId: string;
  name: string;
};

export type NamedLanguageModelProviderConfiguration = {
  baseUrl: string;
  displayName: string;
  discoverModels(value: unknown): DiscoveredOpenAiCompatibleLanguageModel[];
  provider: NamedOpenAiCompatibleLanguageModelProvider;
};

export function openAiCompatibleModels(
  value: unknown,
): DiscoveredOpenAiCompatibleLanguageModel[] {
  if (!isRecord(value)) return [];
  const models = Array.isArray(value.data) ? value.data : [];
  return models.flatMap(openAiCompatibleModel);
}

function openAiCompatibleModel(
  value: unknown,
): DiscoveredOpenAiCompatibleLanguageModel[] {
  if (!isRecord(value)) return [];
  const modelId = stringValue(value.id) ?? stringValue(value.model);
  if (!modelId) return [];
  return [{
    capabilities: defaultLanguageModelCapabilities,
    modelId,
    name: stringValue(value.name) ?? modelId,
  }];
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function stringValue(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}
