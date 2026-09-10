export const languageModelProviders = [
  "googleAi",
  "ollama",
  "openAiCompatible",
] as const;

export type LanguageModelProvider = (typeof languageModelProviders)[number];

export type LanguageModelCapabilities = {
  textGeneration: boolean;
  imageInput: boolean;
  structuredOutput: boolean;
  toolCalling: boolean;
  imageGeneration: boolean;
};

export type LanguageModelConnection = {
  id: string;
  teamId: string;
  name: string;
  provider: LanguageModelProvider;
  baseUrl?: string;
};

export type LanguageModel = {
  id: string;
  teamId: string;
  connectionId: string;
  name: string;
  modelId: string;
  capabilities: LanguageModelCapabilities;
};

export const defaultLanguageModelCapabilities: LanguageModelCapabilities = {
  textGeneration: true,
  imageInput: false,
  structuredOutput: true,
  toolCalling: false,
  imageGeneration: false,
};
