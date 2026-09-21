import {
  defaultLanguageModelCapabilities,
  type LanguageModelProvider,
} from "../../domain/entities/language-model.js";
import {
  namedLanguageModelProviderFor,
} from "../openai-compatible/named-language-model-provider-registry.js";
import {
  openAiCompatibleModels,
  type DiscoveredOpenAiCompatibleLanguageModel,
} from "../openai-compatible/named-language-model-provider.js";

export type LocalLanguageModelConnectionInput = {
  apiKey: string;
  baseUrl?: string;
  provider: LanguageModelProvider;
};

export type DiscoveredLanguageModel = DiscoveredOpenAiCompatibleLanguageModel;

export interface LanguageModelDiscovery {
  discover(input: LocalLanguageModelConnectionInput): Promise<DiscoveredLanguageModel[]>;
}

export class LocalLanguageModelDiscovery implements LanguageModelDiscovery {
  constructor(private readonly request = fetch) {}

  async discover(input: LocalLanguageModelConnectionInput): Promise<DiscoveredLanguageModel[]> {
    const response = await this.fetchModels(input);
    if (!response.ok) throw new LocalLanguageModelDiscoveryError();
    const models = modelsFor(input.provider, await response.json());
    if (models.length === 0) throw new LocalLanguageModelDiscoveryError("Der Anbieter stellt keine Textmodelle bereit.");
    return models;
  }

  private fetchModels(input: LocalLanguageModelConnectionInput): Promise<Response> {
    if (input.provider === "googleAi") return this.request(googleModelsUrl(input.apiKey), {signal: AbortSignal.timeout(10000)});
    const provider = namedLanguageModelProviderFor(input.provider);
    return this.request(openAiModelsUrl(input.baseUrl ?? provider?.baseUrl ?? ""), {
      headers: {Authorization: `Bearer ${input.apiKey}`},
      signal: AbortSignal.timeout(10000),
    });
  }
}

function googleModelsUrl(apiKey: string): URL {
  return new URL(`/v1beta/models?key=${encodeURIComponent(apiKey)}`, "https://generativelanguage.googleapis.com");
}

function openAiModelsUrl(baseUrl: string): URL {
  const url = new URL(baseUrl);
  if (url.hostname === "host.docker.internal" && url.port === "11434") {
    return new URL("/api/tags", url);
  }
  return new URL("models", `${url.toString()}/`);
}

function googleModels(value: unknown): DiscoveredLanguageModel[] {
  if (!isRecord(value) || !Array.isArray(value.models)) return [];
  return value.models.flatMap((model) => {
    if (!isRecord(model) || typeof model.name !== "string" || !supportsGeneration(model)) return [];
    return [discovered(model.name.replace(/^models\//, ""), stringOr(model.displayName, model.name))];
  });
}

function modelsFor(
  provider: LanguageModelProvider,
  value: unknown,
): DiscoveredLanguageModel[] {
  if (provider === "googleAi") return googleModels(value);
  const namedProvider = namedLanguageModelProviderFor(provider);
  return namedProvider?.discoverModels(value) ?? openAiModels(value);
}

function openAiModels(value: unknown): DiscoveredLanguageModel[] {
  const models = openAiCompatibleModels(value);
  if (models.length > 0) return models;
  if (!isRecord(value) || !Array.isArray(value.models)) return [];
  return value.models.flatMap(modelFromProvider);
}

function modelFromProvider(value: unknown): DiscoveredLanguageModel[] {
  if (!isRecord(value)) return [];
  const modelId = stringValue(value.id) ?? stringValue(value.model) ?? stringValue(value.name);
  if (!modelId) return [];
  return [discovered(modelId, stringValue(value.name) ?? modelId)];
}

function stringValue(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function discovered(modelId: string, name: string): DiscoveredLanguageModel {
  return {modelId, name, capabilities: defaultLanguageModelCapabilities};
}

function supportsGeneration(model: Record<string, unknown>): boolean {
  return Array.isArray(model.supportedGenerationMethods) && model.supportedGenerationMethods.includes("generateContent");
}

function stringOr(value: unknown, fallback: string): string {
  return typeof value === "string" && value.length > 0 ? value : fallback;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

export class LocalLanguageModelDiscoveryError extends Error {
  constructor(message = "Modelle konnten nicht vom Anbieter geladen werden.") {
    super(message);
  }
}
