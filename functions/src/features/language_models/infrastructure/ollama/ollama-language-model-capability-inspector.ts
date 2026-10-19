import {type LanguageModelCapabilities} from "../../domain/entities/language-model.js";

export type OllamaCapabilityInspection = {
  baseUrl: string;
  fallback: LanguageModelCapabilities;
  modelId: string;
};

export class OllamaLanguageModelCapabilityInspector {
  constructor(private readonly request: typeof fetch = fetch) {}

  async inspect(input: OllamaCapabilityInspection): Promise<LanguageModelCapabilities> {
    try {
      const response = await this.request(showUrl(input.baseUrl), requestFor(input.modelId));
      if (!response.ok) return input.fallback;
      return capabilitiesFrom(await response.json(), input.fallback);
    } catch {
      return input.fallback;
    }
  }
}

function showUrl(baseUrl: string): string {
  const url = new URL(baseUrl);
  url.pathname = "/api/show";
  url.search = "";
  return url.toString();
}

function requestFor(modelId: string): RequestInit {
  return {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({model: modelId}),
    signal: AbortSignal.timeout(10000),
  };
}

function capabilitiesFrom(
  value: unknown,
  fallback: LanguageModelCapabilities,
): LanguageModelCapabilities {
  if (!isRecord(value) || !Array.isArray(value.capabilities)) return fallback;
  const capabilities = new Set(value.capabilities.filter((value): value is string => typeof value === "string"));
  return {...fallback, imageInput: capabilities.has("vision"), toolCalling: capabilities.has("tools")};
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
