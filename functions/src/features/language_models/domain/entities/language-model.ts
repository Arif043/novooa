export const languageModelProviders = [
  "googleAi",
  "xAi",
  "mistral",
  "openRouter",
  "abacus",
  "huggingFace",
  "elevenLabs",
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
  /** Kann Text als Sprache ausgeben (Text-to-Speech). Fehlt in älteren Einträgen und gilt dann als `false`. */
  speechSynthesis: boolean;
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
  speechSynthesis: false,
};

/** Modelle, die ausschließlich sprechen (z. B. ElevenLabs, Gemini-TTS): Sie können keinen Text beantworten. */
export const speechOnlyLanguageModelCapabilities: LanguageModelCapabilities = {
  textGeneration: false,
  imageInput: false,
  structuredOutput: false,
  toolCalling: false,
  imageGeneration: false,
  speechSynthesis: true,
};

/** Liest Fähigkeiten aus gespeicherten Daten; unbekannte oder fehlende Felder gelten als `false`. */
export function capabilitiesFromRecord(value: Record<string, unknown>): LanguageModelCapabilities {
  return {
    textGeneration: value.textGeneration === true,
    imageInput: value.imageInput === true,
    structuredOutput: value.structuredOutput === true,
    toolCalling: value.toolCalling === true,
    imageGeneration: value.imageGeneration === true,
    speechSynthesis: value.speechSynthesis === true,
  };
}

/**
 * Erkennt reine Sprachmodelle an ihrer ID (`gemini-3.8-flash-tts`, `gpt-4o-mini-tts`,
 * `tts-1`): `tts` muss ein eigenes Wortteil sein, damit Namen wie `settings` nicht treffen.
 */
export function isSpeechModelId(modelId: string): boolean {
  return /(^|[-_./:])tts($|[-_./:])|text-to-speech/i.test(modelId);
}
