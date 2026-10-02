import {
  defaultLanguageModelCapabilities,
  type LanguageModelCapabilities,
} from "../../domain/entities/language-model.js";
import {
  type DiscoveredOpenAiCompatibleLanguageModel,
  type NamedLanguageModelProviderConfiguration,
} from "../openai-compatible/named-language-model-provider.js";

/** OpenAI-kompatibler Router der Inference Providers; die Modellliste steht unter `/models`. */
const huggingFaceBaseUrl = "https://router.huggingface.co/v1";

export const huggingFaceLanguageModelProvider: NamedLanguageModelProviderConfiguration = {
  baseUrl: huggingFaceBaseUrl,
  displayName: "Hugging Face",
  discoverModels: discoverHuggingFaceLanguageModels,
  provider: "huggingFace",
};

type RouterProvider = {
  status?: unknown;
  supports_tools?: unknown;
  supports_structured_output?: unknown;
};

/**
 * `GET https://router.huggingface.co/v1/models` nennt je Modell die Provider, die
 * es bedienen, samt deren Fähigkeiten. Ein Modell taucht nur auf, wenn mindestens
 * ein Provider es aktuell bereitstellt (`status: live`). Werkzeugaufrufe und
 * strukturierte Ausgabe gelten als verfügbar, sobald ein aktiver Provider sie
 * unterstützt — der Router wählt dann einen passenden. Bildeingabe folgt aus
 * den Eingabe-Modalitäten des Modells.
 */
export function discoverHuggingFaceLanguageModels(
  value: unknown,
): DiscoveredOpenAiCompatibleLanguageModel[] {
  if (!isRecord(value) || !Array.isArray(value.data)) return [];
  return value.data.flatMap(modelFrom);
}

function modelFrom(value: unknown): DiscoveredOpenAiCompatibleLanguageModel[] {
  if (!isRecord(value) || typeof value.id !== "string" || value.id.length === 0) return [];
  const providers = Array.isArray(value.providers) ? value.providers.filter(isRecord) as RouterProvider[] : null;
  const live = providers?.filter((provider) => provider.status === "live") ?? null;
  if (live !== null && providers !== null && providers.length > 0 && live.length === 0) return [];
  return [{modelId: value.id, name: value.id, capabilities: capabilitiesFrom(value, live)}];
}

function capabilitiesFrom(
  model: Record<string, unknown>,
  liveProviders: RouterProvider[] | null,
): LanguageModelCapabilities {
  const known = liveProviders !== null && liveProviders.length > 0;
  return {
    ...defaultLanguageModelCapabilities,
    imageInput: modalities(model, "input_modalities").includes("image"),
    imageGeneration: modalities(model, "output_modalities").includes("image"),
    structuredOutput: known
      ? liveProviders.some((provider) => provider.supports_structured_output === true)
      : defaultLanguageModelCapabilities.structuredOutput,
    toolCalling: known && liveProviders.some((provider) => provider.supports_tools === true),
  };
}

function modalities(model: Record<string, unknown>, key: string): string[] {
  const architecture = isRecord(model.architecture) ? model.architecture : {};
  const values = architecture[key];
  return Array.isArray(values) ? values.filter((entry): entry is string => typeof entry === "string") : [];
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
