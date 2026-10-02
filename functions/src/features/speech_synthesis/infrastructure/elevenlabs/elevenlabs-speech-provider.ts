import {type LanguageModelProvider} from "../../../language_models/domain/entities/language-model.js";
import {sdkElevenLabsApi, type ElevenLabsApiFactory} from "../../../language_models/infrastructure/elevenlabs/elevenlabs-api.js";
import {SpeechSynthesisError, type SpeechVoiceList, type SynthesizedSpeech} from "../../domain/entities/speech.js";
import {type SpeechProvider, type SpeechProviderContext} from "../../domain/repositories/speech-provider.js";

/** Sprachausgabe über das offizielle SDK `@elevenlabs/elevenlabs-js`; die Stimmen kommen aus dem Konto des Nutzers. */
export class ElevenLabsSpeechProvider implements SpeechProvider {
  readonly maximumTextLength = 5000;

  constructor(private readonly createApi: ElevenLabsApiFactory = sdkElevenLabsApi) {}

  supports(provider: LanguageModelProvider): boolean {
    return provider === "elevenLabs";
  }

  async synthesize(context: SpeechProviderContext, input: {text: string; voiceId: string}): Promise<SynthesizedSpeech> {
    const bytes = await this.guarded(() => this.createApi(context.apiKey).synthesize({
      voiceId: input.voiceId, modelId: context.model.modelId, text: input.text,
    }));
    if (bytes.length === 0) throw new SpeechSynthesisError("ElevenLabs hat keine Audiodaten geliefert.");
    return {bytes, contentType: "audio/mpeg", fileExtension: "mp3"};
  }

  async listVoices(context: SpeechProviderContext): Promise<SpeechVoiceList> {
    const voices = await this.guarded(() => this.createApi(context.apiKey).listVoices());
    if (voices.length === 0) throw new SpeechSynthesisError("Das ElevenLabs-Konto hat keine Stimmen.");
    return {
      voices: voices.map((voice) => ({
        id: voice.voiceId, name: voice.name,
        ...(voice.description ? {description: voice.description} : {}),
        ...(voice.language ? {language: voice.language} : {}),
      })),
      defaultVoiceId: voices[0].voiceId,
      allowsCustomVoice: false,
    };
  }

  private async guarded<T>(operation: () => Promise<T>): Promise<T> {
    try {
      return await operation();
    } catch (error) {
      if (error instanceof SpeechSynthesisError) throw error;
      throw new SpeechSynthesisError(`ElevenLabs hat die Anfrage abgelehnt${statusOf(error)}${messageOf(error)}`);
    }
  }
}

function statusOf(error: unknown): string {
  const status = (error as {statusCode?: unknown})?.statusCode;
  return typeof status === "number" ? ` (${status})` : "";
}

function messageOf(error: unknown): string {
  const message = error instanceof Error ? error.message.split("\n")[0] : "";
  return message ? `: ${message}` : ".";
}
