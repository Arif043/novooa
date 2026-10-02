import {
  type LanguageModel,
  type LanguageModelConnection,
  type LanguageModelProvider,
} from "../../../language_models/domain/entities/language-model.js";
import {type SpeechVoiceList, type SynthesizedSpeech} from "../entities/speech.js";

export type SpeechProviderContext = {
  connection: LanguageModelConnection;
  model: LanguageModel;
  apiKey: string;
};

/** Sprachausgabe eines Anbieters; ein Adapter pro Protokoll (Google, OpenAI-kompatibel, ElevenLabs). */
export interface SpeechProvider {
  supports(provider: LanguageModelProvider): boolean;
  /** Längster Text, den der Anbieter pro Anfrage annimmt. */
  readonly maximumTextLength: number;
  synthesize(context: SpeechProviderContext, input: {text: string; voiceId: string}): Promise<SynthesizedSpeech>;
  listVoices(context: SpeechProviderContext): Promise<SpeechVoiceList>;
}
