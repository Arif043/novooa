import {
  defaultLanguageModelCapabilities,
  languageModelProviders,
  type LanguageModelProvider,
} from "../../domain/entities/language-model.js";
import {type LanguageModelConfigurationStore} from "../../domain/repositories/language-model-configuration-store.js";
import {LocalLanguageModelDiscovery, type LanguageModelDiscovery} from "./local-language-model-discovery.js";
import {
  namedLanguageModelProviderFor,
} from "../openai-compatible/named-language-model-provider-registry.js";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {type LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";

export class LocalLanguageModelHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly store: LanguageModelConfigurationStore,
    private readonly teamId: string,
    private readonly notifier: LocalRuntimeRealtimeNotifier,
    private readonly discovery: LanguageModelDiscovery = new LocalLanguageModelDiscovery(),
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (request.url === "/v1/language-model-connections" && request.method === "POST") {
      return this.connect(request.body);
    }
    if (request.url !== "/v1/language-models") return null;
    if (request.method === "GET") return {body: {items: await this.store.list(this.teamId)}, statusCode: 200};
    if (request.method !== "POST") return null;
    try {
      const model = await this.store.save(inputFrom(request.body, this.teamId));
      this.notifier.publish("language-models");
      return {body: model, statusCode: 201};
    } catch (error) {
      if (error instanceof LocalLanguageModelRequestError) {
        return {body: {error: error.message}, statusCode: 400};
      }
      throw error;
    }
  }

  private async connect(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const connection = connectionFrom(body, this.teamId);
      const models = await this.discovery.discover({
        provider: connection.connection.provider,
        baseUrl: connection.connection.baseUrl,
        apiKey: connection.apiKey,
      });
      const saved = await this.store.saveConnection({...connection, models});
      this.notifier.publish("language-models");
      return {body: {items: saved}, statusCode: 201};
    } catch (error) {
      const message = error instanceof Error ? error.message : "Sprachmodell-Verbindung konnte nicht hergestellt werden.";
      return {body: {error: message}, statusCode: 400};
    }
  }
}

function connectionFrom(value: unknown, teamId: string) {
  const input = record(value);
  const provider = providerFrom(input.provider);
  const baseUrl = baseUrlFrom(input.baseUrl, provider);
  return {
    teamId,
    connection: {name: connectionName(provider, baseUrl), provider, ...(baseUrl ? {baseUrl} : {})},
    apiKey: apiKeyFrom(input.apiKey, baseUrl),
  };
}

function connectionName(provider: LanguageModelProvider, baseUrl: string | undefined): string {
  if (provider === "googleAi") return "Google AI";
  if (provider === "ollama") return "Ollama";
  const namedProvider = namedLanguageModelProviderFor(provider);
  if (namedProvider) return namedProvider.displayName;
  return new URL(baseUrl ?? "").hostname;
}

function inputFrom(value: unknown, teamId: string) {
  const input = record(value);
  const provider = providerFrom(input.provider);
  const baseUrl = baseUrlFrom(input.baseUrl, provider);
  return {
    teamId,
    connection: {name: text(input.connectionName, "connectionName", 120), provider, ...(baseUrl ? {baseUrl} : {})},
    model: {
      name: text(input.name, "name", 120),
      modelId: text(input.languageModelId, "languageModelId", 200),
      capabilities: defaultLanguageModelCapabilities,
    },
    apiKey: apiKeyFrom(input.apiKey, baseUrl),
  };
}

function apiKeyFrom(value: unknown, baseUrl: string | undefined): string {
  if (baseUrl && new URL(baseUrl).hostname === "host.docker.internal") {
    return optionalText(value, "local");
  }
  return text(value, "apiKey", 4096, 8);
}

function providerFrom(value: unknown): LanguageModelProvider {
  if (typeof value === "string" && languageModelProviders.includes(value as LanguageModelProvider)) {
    return value as LanguageModelProvider;
  }
  throw new LocalLanguageModelRequestError("provider wird nicht unterstützt.");
}

function baseUrlFrom(value: unknown, provider: LanguageModelProvider): string | undefined {
  if (provider === "googleAi") return undefined;
  if (provider === "ollama" && value === undefined) return "http://host.docker.internal:11434/v1";
  const namedProvider = namedLanguageModelProviderFor(provider);
  if (namedProvider) return namedProviderBaseUrl(value, namedProvider.baseUrl);
  const url = text(value, "baseUrl", 2048);
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== "https:" && parsed.hostname !== "host.docker.internal") {
      throw new LocalLanguageModelRequestError("baseUrl muss HTTPS oder host.docker.internal verwenden.");
    }
    return parsed.toString().replace(/\/$/, "");
  } catch (error) {
    if (error instanceof LocalLanguageModelRequestError) throw error;
    throw new LocalLanguageModelRequestError("baseUrl ist ungültig.");
  }
}

function namedProviderBaseUrl(value: unknown, defaultBaseUrl: string): string {
  if (value === undefined) return defaultBaseUrl;
  const baseUrl = text(value, "baseUrl", 2048);
  if (normalizedUrlOrNull(baseUrl) !== defaultBaseUrl) {
    throw new LocalLanguageModelRequestError("Die API-Adresse dieses Anbieters kann nicht geändert werden.");
  }
  return defaultBaseUrl;
}

function normalizedUrlOrNull(value: string): string | null {
  try {
    return new URL(value).toString().replace(/\/$/, "");
  } catch (_) {
    return null;
  }
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new LocalLanguageModelRequestError("Die Sprachmodell-Konfiguration erwartet ein Objekt.");
}

function text(value: unknown, name: string, max: number, min = 1): string {
  if (typeof value !== "string" || value.trim().length < min || value.length > max) {
    throw new LocalLanguageModelRequestError(`${name} ist ungültig.`);
  }
  return value.trim();
}

function optionalText(value: unknown, fallback: string): string {
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : fallback;
}

class LocalLanguageModelRequestError extends Error {}
