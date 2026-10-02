import {type LanguageModelProvider} from "../../../language_models/domain/entities/language-model.js";
import {SpeechSynthesisError, type SpeechVoice, type SpeechVoiceList, type SynthesizedSpeech} from "../../domain/entities/speech.js";
import {type SpeechProvider, type SpeechProviderContext} from "../../domain/repositories/speech-provider.js";

const apiBase = "https://generativelanguage.googleapis.com/v1beta";
const defaultVoiceId = "Kore";
const requestTimeoutMilliseconds = 120_000;
const voicePageSize = 1000;
const maximumVoicePages = 3;

/**
 * Die 30 vorgefertigten Stimmen von Gemini (dokumentiert) — nur der Notbehelf, wenn die
 * Abfrage der Stimmenbibliothek fehlschlägt oder leer bleibt.
 */
export const googlePrebuiltVoices: readonly SpeechVoice[] = [
  ["Zephyr", "Hell"], ["Puck", "Lebhaft"], ["Charon", "Informativ"], ["Kore", "Bestimmt"], ["Fenrir", "Begeistert"],
  ["Leda", "Jugendlich"], ["Orus", "Bestimmt"], ["Aoede", "Luftig"], ["Callirrhoe", "Entspannt"], ["Autonoe", "Hell"],
  ["Enceladus", "Hauchig"], ["Iapetus", "Klar"], ["Umbriel", "Entspannt"], ["Algieba", "Weich"], ["Despina", "Weich"],
  ["Erinome", "Klar"], ["Algenib", "Rau"], ["Rasalgethi", "Informativ"], ["Laomedeia", "Lebhaft"], ["Achernar", "Sanft"],
  ["Alnilam", "Bestimmt"], ["Schedar", "Gleichmäßig"], ["Gacrux", "Reif"], ["Pulcherrima", "Direkt"], ["Achird", "Freundlich"],
  ["Zubenelgenubi", "Locker"], ["Vindemiatrix", "Sanft"], ["Sadachbia", "Munter"], ["Sadaltager", "Kenntnisreich"], ["Sulafat", "Warm"],
].map(([id, description]) => ({id, name: id, description}));

/**
 * Gemini-TTS über die Interactions-API (`POST /v1beta/interactions`). Die Antwort ist
 * standardmäßig eine fertige WAV-Datei (24 kHz, mono, 16 Bit). Stimmen kommen aus
 * `GET /v1beta/voices`.
 */
export class GoogleSpeechProvider implements SpeechProvider {
  readonly maximumTextLength = 8000;

  constructor(private readonly request: typeof fetch = fetch) {}

  supports(provider: LanguageModelProvider): boolean {
    return provider === "googleAi";
  }

  async synthesize(context: SpeechProviderContext, input: {text: string; voiceId: string}): Promise<SynthesizedSpeech> {
    const response = await this.request(`${apiBase}/interactions`, {
      method: "POST",
      headers: {"x-goog-api-key": context.apiKey, "content-type": "application/json"},
      body: JSON.stringify(interactionFor(context.model.modelId, input)),
      signal: AbortSignal.timeout(requestTimeoutMilliseconds),
    });
    if (!response.ok) throw await rejection("Google AI", response);
    const audio = audioFrom(await response.json());
    if (audio === null) throw new SpeechSynthesisError("Google AI hat keine Audiodaten geliefert. Prüfe, ob das Modell Sprachausgabe unterstützt.");
    return wavFrom(new Uint8Array(Buffer.from(audio.data, "base64")), audio.mimeType);
  }

  async listVoices(context: SpeechProviderContext): Promise<SpeechVoiceList> {
    const fetched = await this.libraryVoices(context.apiKey).catch(() => []);
    const voices = fetched.length > 0 ? sortedByName(fetched) : [...googlePrebuiltVoices];
    return {voices, defaultVoiceId: voices.some((voice) => voice.id === defaultVoiceId) ? defaultVoiceId : voices[0].id, allowsCustomVoice: false};
  }

  private async libraryVoices(apiKey: string): Promise<SpeechVoice[]> {
    const voices: SpeechVoice[] = [];
    let pageToken = "";
    for (let page = 0; page < maximumVoicePages; page++) {
      const query = new URLSearchParams({page_size: String(voicePageSize), ...(pageToken ? {page_token: pageToken} : {})});
      const response = await this.request(`${apiBase}/voices?${query}`, {
        headers: {"x-goog-api-key": apiKey}, signal: AbortSignal.timeout(15_000),
      });
      if (!response.ok) return voices;
      const body = await response.json() as Record<string, unknown>;
      voices.push(...(Array.isArray(body.voices) ? body.voices.flatMap(voiceFrom) : []));
      pageToken = stringOf(body.next_page_token) ?? stringOf(body.nextPageToken) ?? "";
      if (!pageToken) break;
    }
    return voices;
  }
}

function interactionFor(modelId: string, input: {text: string; voiceId: string}) {
  return {
    model: modelId,
    input: [{type: "user_input", content: [{type: "text", text: input.text}]}],
    response_format: {type: "audio"},
    generation_config: {speech_config: [{voice: input.voiceId}]},
  };
}

/** Das letzte Audio-Element der Modellausgabe (`steps[].content[]`), Base64-kodiert. */
function audioFrom(body: unknown): {data: string; mimeType: string} | null {
  const steps = isRecord(body) && Array.isArray(body.steps) ? body.steps : [];
  const audio = steps
    .filter((step) => isRecord(step) && step.type === "model_output" && Array.isArray(step.content))
    .flatMap((step) => (step as {content: unknown[]}).content)
    .filter((part): part is Record<string, unknown> => isRecord(part) && part.type === "audio" && typeof part.data === "string");
  if (audio.length === 0) return null;
  const last = audio[audio.length - 1];
  return {data: last.data as string, mimeType: stringOf(last.mime_type) ?? stringOf(last.mimeType) ?? ""};
}

const defaultSampleRate = 24_000;

/**
 * Ältere TTS-Modelle liefern rohes 16-Bit-PCM (`audio/L16;rate=24000`), neuere fertiges WAV.
 * PCM wird mit einem WAV-Kopf versehen, damit überall eine abspielbare Datei entsteht.
 */
export function wavFrom(bytes: Uint8Array, mimeType: string): SynthesizedSpeech {
  const isWav = /wav/i.test(mimeType) || String.fromCharCode(...bytes.slice(0, 4)) === "RIFF";
  if (isWav) return {bytes, contentType: "audio/wav", fileExtension: "wav"};
  const sampleRate = Number(/rate=(\d+)/i.exec(mimeType)?.[1] ?? defaultSampleRate);
  const header = Buffer.alloc(44);
  header.write("RIFF", 0); header.writeUInt32LE(36 + bytes.length, 4); header.write("WAVEfmt ", 8);
  header.writeUInt32LE(16, 16); header.writeUInt16LE(1, 20); header.writeUInt16LE(1, 22);
  header.writeUInt32LE(sampleRate, 24); header.writeUInt32LE(sampleRate * 2, 28);
  header.writeUInt16LE(2, 32); header.writeUInt16LE(16, 34); header.write("data", 36); header.writeUInt32LE(bytes.length, 40);
  return {bytes: Buffer.concat([header, bytes]), contentType: "audio/wav", fileExtension: "wav"};
}

function voiceFrom(value: unknown): SpeechVoice[] {
  if (!isRecord(value)) return [];
  const id = stringOf(value.id);
  if (id === undefined) return [];
  const description = [stringOf(value.description), stringOf(value.gender), stringOf(value.accent)].filter(Boolean).join(" · ");
  const language = stringOf(value.language_code) ?? stringOf(value.languageCode);
  return [{
    id, name: stringOf(value.display_name) ?? stringOf(value.displayName) ?? id,
    ...(description ? {description} : {}), ...(language ? {language} : {}),
  }];
}

function sortedByName(voices: SpeechVoice[]): SpeechVoice[] {
  return [...new Map(voices.map((voice) => [voice.id, voice])).values()].sort((a, b) => a.name.localeCompare(b.name, "de"));
}

async function rejection(provider: string, response: Response): Promise<SpeechSynthesisError> {
  const body = await response.json().catch(() => ({})) as Record<string, unknown>;
  const message = isRecord(body.error) ? stringOf(body.error.message) : undefined;
  return new SpeechSynthesisError(`${provider} hat die Sprachausgabe abgelehnt (${response.status})${message ? `: ${message}` : "."}`);
}

function stringOf(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
