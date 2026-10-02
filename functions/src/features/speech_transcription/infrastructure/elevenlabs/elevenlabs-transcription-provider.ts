import {type LanguageModelProvider} from "../../../language_models/domain/entities/language-model.js";
import {sdkElevenLabsApi, type ElevenLabsApiFactory} from "../../../language_models/infrastructure/elevenlabs/elevenlabs-api.js";
import {SpeechTranscriptionError, type AudioInput} from "../../domain/entities/transcription.js";
import {type TranscriptionProvider, type TranscriptionProviderContext} from "../../domain/repositories/transcription-provider.js";

/** Transkription mit ElevenLabs Scribe (`scribe_v1`, `scribe_v2`) über das SDK. */
export class ElevenLabsTranscriptionProvider implements TranscriptionProvider {
  readonly maximumAudioBytes = 1024 * 1024 * 1024;

  constructor(private readonly createApi: ElevenLabsApiFactory = sdkElevenLabsApi) {}

  supports(provider: LanguageModelProvider): boolean {
    return provider === "elevenLabs";
  }

  async transcribe(context: TranscriptionProviderContext, audio: AudioInput): Promise<string> {
    try {
      return await this.createApi(context.apiKey).transcribe({
        modelId: context.model.modelId, bytes: audio.bytes, contentType: audio.contentType,
      });
    } catch (error) {
      if (error instanceof SpeechTranscriptionError) throw error;
      const status = (error as {statusCode?: unknown})?.statusCode;
      const message = error instanceof Error ? error.message.split("\n")[0] : "";
      throw new SpeechTranscriptionError(
        `ElevenLabs hat die Transkription abgelehnt${typeof status === "number" ? ` (${status})` : ""}${message ? `: ${message}` : "."}`,
      );
    }
  }
}
