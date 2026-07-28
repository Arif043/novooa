import {openAICompatible} from "@genkit-ai/compat-oai";
import {googleAI} from "@genkit-ai/google-genai";
import {modelRef, type ModelArgument} from "genkit";
import {type GenkitPluginV2} from "genkit/plugin";

type AiProviderKind = "google" | "minimax" | "openai-compatible" | "local";

type OpenAiCompatibleProvider = {
  kind: "minimax" | "openai-compatible" | "local";
  name: string;
  apiKey: string;
  baseUrl: string;
  textModel: string;
  reasoningModel: string;
};

type AiProviderConfig =
  | {
      kind: "google";
      textModel: string;
      reasoningModel: string;
    }
  | OpenAiCompatibleProvider;

const defaultGoogleTextModel = "gemini-3.1-flash-lite";
const defaultGoogleReasoningModel = "gemini-3.1-flash-lite";
const defaultLocalProviderName = "local";
const defaultLocalBaseUrl = "http://127.0.0.1:11434/v1";

export function aiProviderPlugins(): GenkitPluginV2[] {
  const config = aiProviderConfig();
  if (config.kind === "google") return [googleAI()];
  return [
    openAICompatible({
      name: config.name,
      apiKey: config.apiKey,
      baseURL: config.baseUrl,
    }),
  ];
}

export function textModel(): ModelArgument {
  return modelFor(aiProviderConfig(), "textModel");
}

export function reasoningModel(): ModelArgument {
  return modelFor(aiProviderConfig(), "reasoningModel");
}

export function modelLogContext() {
  const config = aiProviderConfig();
  if (config.kind === "google") {
    return {
      provider: config.kind,
      textModel: config.textModel,
      reasoningModel: config.reasoningModel,
    };
  }
  return {
    provider: config.kind,
    endpoint: config.name,
    textModel: config.textModel,
    reasoningModel: config.reasoningModel,
  };
}

function modelFor(
  config: AiProviderConfig,
  modelKey: "textModel" | "reasoningModel",
): ModelArgument {
  if (config.kind === "google") return googleAI.model(config[modelKey]);
  return modelRef({name: `${config.name}/${config[modelKey]}`});
}

function aiProviderConfig(): AiProviderConfig {
  const kind = providerKind();
  if (kind === "google") return googleConfig();
  if (kind === "minimax") return minimaxConfig();
  if (kind === "local") return localConfig();
  return openAiCompatibleConfig();
}

function providerKind(): AiProviderKind {
  const value = optionalEnv("AI_PROVIDER") ?? "google";
  if (isAiProviderKind(value)) return value;
  throw new Error(`Unsupported AI_PROVIDER: ${value}.`);
}

function isAiProviderKind(value: string): value is AiProviderKind {
  return [
    "google",
    "minimax",
    "openai-compatible",
    "local",
  ].includes(value);
}

function googleConfig(): AiProviderConfig {
  return {
    kind: "google",
    textModel: optionalEnv("GOOGLE_TEXT_MODEL") ?? defaultGoogleTextModel,
    reasoningModel:
      optionalEnv("GOOGLE_REASONING_MODEL") ?? defaultGoogleReasoningModel,
  };
}

function minimaxConfig(): OpenAiCompatibleProvider {
  return {
    kind: "minimax",
    name: "minimax",
    apiKey: requiredEnv("MINIMAX_API_KEY"),
    baseUrl: requiredEnv("MINIMAX_BASE_URL"),
    textModel: requiredEnv("MINIMAX_MODEL"),
    reasoningModel: optionalEnv("MINIMAX_REASONING_MODEL") ??
      requiredEnv("MINIMAX_MODEL"),
  };
}

function localConfig(): OpenAiCompatibleProvider {
  return {
    kind: "local",
    name: optionalEnv("LOCAL_AI_PROVIDER_NAME") ?? defaultLocalProviderName,
    apiKey: optionalEnv("LOCAL_AI_API_KEY") ?? "local",
    baseUrl: optionalEnv("LOCAL_AI_BASE_URL") ?? defaultLocalBaseUrl,
    textModel: requiredEnv("LOCAL_AI_TEXT_MODEL"),
    reasoningModel:
      optionalEnv("LOCAL_AI_REASONING_MODEL") ?? requiredEnv("LOCAL_AI_TEXT_MODEL"),
  };
}

function openAiCompatibleConfig(): OpenAiCompatibleProvider {
  return {
    kind: "openai-compatible",
    name: requiredEnv("OPENAI_COMPATIBLE_PROVIDER_NAME"),
    apiKey: requiredEnv("OPENAI_COMPATIBLE_API_KEY"),
    baseUrl: requiredEnv("OPENAI_COMPATIBLE_BASE_URL"),
    textModel: requiredEnv("OPENAI_COMPATIBLE_TEXT_MODEL"),
    reasoningModel: optionalEnv("OPENAI_COMPATIBLE_REASONING_MODEL") ??
      requiredEnv("OPENAI_COMPATIBLE_TEXT_MODEL"),
  };
}

function requiredEnv(name: string): string {
  const value = optionalEnv(name);
  if (value) return value;
  throw new Error(`${name} is required for the selected AI provider.`);
}

function optionalEnv(name: string): string | undefined {
  const value = process.env[name]?.trim();
  return value && value.length > 0 ? value : undefined;
}
