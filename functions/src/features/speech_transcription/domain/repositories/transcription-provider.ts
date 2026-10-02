import {
  type LanguageModel,
  type LanguageModelConnection,
  type LanguageModelProvider,
} from "../../../language_models/domain/entities/language-model.js";
import {type AudioInput} from "../entities/transcription.js";

export type TranscriptionProviderContext = {
  connection: LanguageModelConnection;
  model: LanguageModel;
  apiKey: string;
};

/** Transkription eines Anbieters; ein Adapter pro Protokoll. */
export interface TranscriptionProvider {
  supports(provider: LanguageModelProvider): boolean;
  /** Größte Audiodatei, die der Anbieter pro Anfrage annimmt. */
  readonly maximumAudioBytes: number;
  transcribe(context: TranscriptionProviderContext, audio: AudioInput): Promise<string>;
}
