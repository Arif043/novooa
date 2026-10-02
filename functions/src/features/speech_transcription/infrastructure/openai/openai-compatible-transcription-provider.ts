import {type LanguageModelProvider} from "../../../language_models/domain/entities/language-model.js";
import {namedLanguageModelProviderFor} from "../../../language_models/infrastructure/openai-compatible/named-language-model-provider-registry.js";
import {SpeechTranscriptionError, type AudioInput} from "../../domain/entities/transcription.js";
import {type TranscriptionProvider, type TranscriptionProviderContext} from "../../domain/repositories/transcription-provider.js";

const requestTimeoutMilliseconds = 180_000;

/** `POST {Basis-URL}/audio/transcriptions` (multipart) im OpenAI-Format, z. B. `whisper-1`, `gpt-4o-transcribe`. */
export class OpenAiCompatibleTranscriptionProvider implements TranscriptionProvider {
  readonly maximumAudioBytes = 25 * 1024 * 1024;
  private readonly unsupported: ReadonlySet<LanguageModelProvider> = new Set(["googleAi", "elevenLabs", "ollama"]);

  constructor(private readonly request: typeof fetch = fetch) {}

  supports(provider: LanguageModelProvider): boolean {
    return !this.unsupported.has(provider);
  }

  async transcribe(context: TranscriptionProviderContext, audio: AudioInput): Promise<string> {
    const form = new FormData();
    form.set("model", context.model.modelId);
    form.set("file", new Blob([Uint8Array.from(audio.bytes)], {type: audio.contentType}), audio.displayName);
    const response = await this.request(transcriptionUrl(context), {
      method: "POST",
      headers: {authorization: `Bearer ${context.apiKey}`},
      body: form,
      signal: AbortSignal.timeout(requestTimeoutMilliseconds),
    });
    const body = await response.json().catch(() => ({})) as Record<string, unknown>;
    if (!response.ok) throw rejection(context.connection.name, response.status, body);
    if (typeof body.text !== "string") throw new SpeechTranscriptionError(`${context.connection.name} hat keinen Text geliefert.`);
    return body.text.trim();
  }
}

function transcriptionUrl(context: TranscriptionProviderContext): string {
  const baseUrl = namedLanguageModelProviderFor(context.connection.provider)?.baseUrl ?? context.connection.baseUrl;
  if (!baseUrl) throw new SpeechTranscriptionError("Der Verbindung fehlt die API-Adresse.");
  return `${baseUrl.replace(/\/$/, "")}/audio/transcriptions`;
}

function rejection(provider: string, status: number, body: Record<string, unknown>): SpeechTranscriptionError {
  const error = body.error;
  const message = typeof error === "string" ? error : (error as {message?: unknown} | undefined)?.message;
  const detail = typeof message === "string" && message.length > 0 ? `: ${message}` : ".";
  return new SpeechTranscriptionError(`${provider} hat die Transkription abgelehnt (${status})${detail}`);
}
