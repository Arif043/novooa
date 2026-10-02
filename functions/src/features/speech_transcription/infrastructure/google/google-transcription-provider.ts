import {type LanguageModelProvider} from "../../../language_models/domain/entities/language-model.js";
import {SpeechTranscriptionError, type AudioInput} from "../../domain/entities/transcription.js";
import {type TranscriptionProvider, type TranscriptionProviderContext} from "../../domain/repositories/transcription-provider.js";

const apiBase = "https://generativelanguage.googleapis.com/v1beta";
const requestTimeoutMilliseconds = 180_000;
const instruction = "Transkribiere die Audioaufnahme wörtlich in der gesprochenen Sprache. Gib ausschließlich den Text aus, ohne Kommentar.";

/**
 * Google hat keine eigenen Transkriptionsmodelle, aber jedes Gemini-Modell versteht
 * Audio. Die Datei geht inline an `generateContent` (Grenze 20 MB der Anfrage).
 */
export class GoogleTranscriptionProvider implements TranscriptionProvider {
  readonly maximumAudioBytes = 14 * 1024 * 1024;

  constructor(private readonly request: typeof fetch = fetch) {}

  supports(provider: LanguageModelProvider): boolean {
    return provider === "googleAi";
  }

  async transcribe(context: TranscriptionProviderContext, audio: AudioInput): Promise<string> {
    const response = await this.request(`${apiBase}/models/${encodeURIComponent(context.model.modelId)}:generateContent`, {
      method: "POST",
      headers: {"x-goog-api-key": context.apiKey, "content-type": "application/json"},
      body: JSON.stringify({contents: [{parts: [
        {text: instruction},
        {inline_data: {mime_type: audio.contentType, data: Buffer.from(audio.bytes).toString("base64")}},
      ]}]}),
      signal: AbortSignal.timeout(requestTimeoutMilliseconds),
    });
    const body = await response.json().catch(() => ({})) as Record<string, unknown>;
    if (!response.ok) throw rejection(response.status, body);
    return textFrom(body);
  }
}

function textFrom(body: Record<string, unknown>): string {
  const candidates = Array.isArray(body.candidates) ? body.candidates : [];
  const parts = candidates.flatMap((candidate) => {
    const content = (candidate as {content?: {parts?: unknown}} | null)?.content;
    return Array.isArray(content?.parts) ? content.parts : [];
  });
  const text = parts.map((part) => (part as {text?: unknown}).text).filter((value): value is string => typeof value === "string").join("").trim();
  if (text.length === 0) throw new SpeechTranscriptionError("Google AI hat keinen Text geliefert. Prüfe, ob das Modell Audio versteht.");
  return text;
}

function rejection(status: number, body: Record<string, unknown>): SpeechTranscriptionError {
  const error = body.error as {message?: unknown} | undefined;
  const detail = typeof error?.message === "string" ? `: ${error.message}` : ".";
  return new SpeechTranscriptionError(`Google AI hat die Transkription abgelehnt (${status})${detail}`);
}
