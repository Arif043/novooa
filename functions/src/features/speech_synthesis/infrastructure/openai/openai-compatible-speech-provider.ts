import {type LanguageModelProvider} from "../../../language_models/domain/entities/language-model.js";
import {namedLanguageModelProviderFor} from "../../../language_models/infrastructure/openai-compatible/named-language-model-provider-registry.js";
import {SpeechSynthesisError, type SpeechVoice, type SpeechVoiceList, type SynthesizedSpeech} from "../../domain/entities/speech.js";
import {type SpeechProvider, type SpeechProviderContext} from "../../domain/repositories/speech-provider.js";

const defaultVoiceId = "alloy";
const requestTimeoutMilliseconds = 120_000;

/** Die eingebauten Stimmen der OpenAI-Sprach-API; eine Abfrage-API gibt es dafür nicht. */
export const openAiVoices: readonly SpeechVoice[] = [
  "alloy", "ash", "ballad", "coral", "echo", "fable", "nova", "onyx", "sage", "shimmer", "verse",
].map((id) => ({id, name: id}));

/**
 * `POST {Basis-URL}/audio/speech` im OpenAI-Format. Das gilt für OpenAI selbst und für
 * kompatible Dienste, die den Endpunkt anbieten; Dienste ohne ihn antworten mit einem
 * Fehler, den die Meldung an den Nutzer weitergibt. Eigene Stimmen eines solchen
 * Dienstes lassen sich als Freitext angeben.
 */
export class OpenAiCompatibleSpeechProvider implements SpeechProvider {
  readonly maximumTextLength = 4096;
  private readonly unsupported: ReadonlySet<LanguageModelProvider> = new Set(["googleAi", "elevenLabs", "ollama"]);

  constructor(private readonly request: typeof fetch = fetch) {}

  supports(provider: LanguageModelProvider): boolean {
    return !this.unsupported.has(provider);
  }

  async synthesize(context: SpeechProviderContext, input: {text: string; voiceId: string}): Promise<SynthesizedSpeech> {
    const response = await this.request(speechUrl(context), {
      method: "POST",
      headers: {authorization: `Bearer ${context.apiKey}`, "content-type": "application/json"},
      body: JSON.stringify({model: context.model.modelId, input: input.text, voice: input.voiceId, response_format: "mp3"}),
      signal: AbortSignal.timeout(requestTimeoutMilliseconds),
    });
    if (!response.ok) throw await rejection(context.connection.name, response);
    const bytes = new Uint8Array(await response.arrayBuffer());
    if (bytes.length === 0) throw new SpeechSynthesisError(`${context.connection.name} hat keine Audiodaten geliefert.`);
    return {bytes, contentType: "audio/mpeg", fileExtension: "mp3"};
  }

  async listVoices(): Promise<SpeechVoiceList> {
    return {voices: [...openAiVoices], defaultVoiceId, allowsCustomVoice: true};
  }
}

function speechUrl(context: SpeechProviderContext): string {
  const baseUrl = namedLanguageModelProviderFor(context.connection.provider)?.baseUrl ?? context.connection.baseUrl;
  if (!baseUrl) throw new SpeechSynthesisError("Der Verbindung fehlt die API-Adresse.");
  return `${baseUrl.replace(/\/$/, "")}/audio/speech`;
}

async function rejection(provider: string, response: Response): Promise<SpeechSynthesisError> {
  const body = await response.json().catch(() => ({})) as Record<string, unknown>;
  const error = body.error;
  const message = typeof error === "string" ? error
    : error !== null && typeof error === "object" ? (error as Record<string, unknown>).message : undefined;
  const detail = typeof message === "string" && message.length > 0 ? `: ${message}` : ".";
  return new SpeechSynthesisError(`${provider} hat die Sprachausgabe abgelehnt (${response.status})${detail}`);
}
