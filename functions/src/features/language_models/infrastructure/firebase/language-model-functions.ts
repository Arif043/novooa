import {HttpsError, onCall} from "firebase-functions/v2/https";
import {currentTeamIdForUid} from "../../../teams/infrastructure/firebase/firebase-team-context.js";
import {
  defaultLanguageModelCapabilities,
  languageModelProviders,
  type LanguageModelCapabilities,
  type LanguageModelProvider,
} from "../../domain/entities/language-model.js";
import {FirestoreLanguageModelCatalog} from "./firestore-language-model-catalog.js";
import {
  languageModelCipher,
  languageModelEncryptionKey,
} from "./language-model-encryption.js";
import {
  namedLanguageModelProviderFor,
} from "../openai-compatible/named-language-model-provider-registry.js";

export const saveLanguageModel = onCall(
  {secrets: [languageModelEncryptionKey]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Anmeldung erforderlich.");
    const input = inputFrom(request.data);
    const teamId = await currentTeamIdForUid(uid);
    const catalog = new FirestoreLanguageModelCatalog(languageModelCipher);
    const model = await catalog.save({...input, teamId});
    return {modelId: model.id, connectionId: model.connectionId};
  },
);

function inputFrom(data: unknown): {
  connectionId?: string;
  modelId?: string;
  connection: {
    name: string;
    provider: LanguageModelProvider;
    baseUrl?: string;
  };
  model: {
    name: string;
    modelId: string;
    capabilities: LanguageModelCapabilities;
  };
  apiKey: string;
} {
  const input = record(data, "Die Sprachmodell-Konfiguration erwartet ein Objekt.");
  const provider = providerFrom(input.provider);
  const baseUrl = baseUrlFrom(input.baseUrl, provider);
  return {
    ...(optionalId(input.connectionId) ? {connectionId: optionalId(input.connectionId)} : {}),
    ...(optionalId(input.modelId) ? {modelId: optionalId(input.modelId)} : {}),
    connection: {
      name: boundedString(input.connectionName, "connectionName", 120),
      provider,
      ...(baseUrl ? {baseUrl} : {}),
    },
    model: {
      name: boundedString(input.name, "name", 120),
      modelId: boundedString(input.languageModelId, "languageModelId", 200),
      capabilities: capabilitiesFrom(input.capabilities),
    },
    apiKey: boundedString(input.apiKey, "apiKey", 4096, 8),
  };
}

function providerFrom(value: unknown): LanguageModelProvider {
  if (value === "ollama") throw invalidInput("Ollama ist nur für die lokale Runtime verfügbar.");
  if (typeof value === "string" && languageModelProviders.includes(
    value as LanguageModelProvider,
  )) return value as LanguageModelProvider;
  throw invalidInput("provider wird nicht unterstützt.");
}

function baseUrlFrom(
  value: unknown,
  provider: LanguageModelProvider,
): string | undefined {
  if (provider === "googleAi") return undefined;
  const namedProvider = namedLanguageModelProviderFor(provider);
  if (namedProvider) return namedProviderBaseUrl(value, namedProvider.baseUrl);
  const url = boundedString(value, "baseUrl", 2048);
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== "https:") {
      throw invalidInput("baseUrl muss HTTPS verwenden.");
    }
    return parsed.toString().replace(/\/$/, "");
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw invalidInput("baseUrl ist ungültig.");
  }
}

function namedProviderBaseUrl(value: unknown, defaultBaseUrl: string): string {
  if (value === undefined) return defaultBaseUrl;
  const suppliedBaseUrl = boundedString(value, "baseUrl", 2048);
  if (normalizedUrlOrNull(suppliedBaseUrl) !== defaultBaseUrl) {
    throw invalidInput("Die API-Adresse dieses Anbieters kann nicht geändert werden.");
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

function capabilitiesFrom(value: unknown): LanguageModelCapabilities {
  if (value === undefined) return defaultLanguageModelCapabilities;
  const capabilities = record(value, "capabilities muss ein Objekt sein.");
  return {
    textGeneration: capabilities.textGeneration === true,
    imageInput: capabilities.imageInput === true,
    structuredOutput: capabilities.structuredOutput === true,
    toolCalling: capabilities.toolCalling === true,
    imageGeneration: capabilities.imageGeneration === true,
  };
}

function optionalId(value: unknown): string | undefined {
  if (typeof value !== "string" || value.trim().length === 0) return undefined;
  return boundedString(value, "id", 200);
}

function boundedString(
  value: unknown,
  name: string,
  maxLength: number,
  minLength = 1,
): string {
  if (
    typeof value !== "string" || value.trim().length < minLength ||
    value.length > maxLength
  ) throw invalidInput(`${name} ist ungültig.`);
  return value.trim();
}

function record(value: unknown, message: string): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw invalidInput(message);
}

function invalidInput(message: string): HttpsError {
  return new HttpsError("invalid-argument", message);
}
