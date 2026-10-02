import {ElevenLabsClient} from "@elevenlabs/elevenlabs-js";

export type ElevenLabsSpeechModel = {modelId: string; name: string; maximumTextLength?: number};

export type ElevenLabsVoice = {
  voiceId: string;
  name: string;
  description?: string;
  category?: string;
  language?: string;
};

/**
 * Was die App von ElevenLabs braucht — eine schmale Fassade vor dem SDK
 * `@elevenlabs/elevenlabs-js`, damit Domain und Tests das SDK nicht kennen.
 */
export interface ElevenLabsApi {
  listSpeechModels(): Promise<ElevenLabsSpeechModel[]>;
  listVoices(): Promise<ElevenLabsVoice[]>;
  synthesize(input: {voiceId: string; modelId: string; text: string}): Promise<Uint8Array>;
  transcribe(input: {modelId: string; bytes: Uint8Array; contentType: string}): Promise<string>;
}

export type ElevenLabsApiFactory = (apiKey: string) => ElevenLabsApi;

/** Seiten à 100 Stimmen; mehr als fünf Seiten lädt die App nicht (die Suche in der UI engt ein). */
const voicePageSize = 100;
const maximumVoicePages = 5;
const audioFormat = "mp3_44100_128";

export const sdkElevenLabsApi: ElevenLabsApiFactory = (apiKey) => new SdkElevenLabsApi(new ElevenLabsClient({apiKey}));

export class SdkElevenLabsApi implements ElevenLabsApi {
  constructor(private readonly client: ElevenLabsClient) {}

  async listSpeechModels(): Promise<ElevenLabsSpeechModel[]> {
    const models = await this.client.models.list();
    return models
      .filter((model) => model.canDoTextToSpeech === true)
      .map((model) => ({
        modelId: model.modelId,
        name: model.name ?? model.modelId,
        ...(model.maximumTextLengthPerRequest ? {maximumTextLength: model.maximumTextLengthPerRequest} : {}),
      }));
  }

  async listVoices(): Promise<ElevenLabsVoice[]> {
    const voices: ElevenLabsVoice[] = [];
    let nextPageToken: string | undefined;
    for (let page = 0; page < maximumVoicePages; page++) {
      const response = await this.client.voices.search({pageSize: voicePageSize, nextPageToken});
      voices.push(...response.voices.map(voiceFrom));
      if (!response.hasMore || !response.nextPageToken) break;
      nextPageToken = response.nextPageToken;
    }
    return voices;
  }

  async transcribe(input: {modelId: string; bytes: Uint8Array; contentType: string}): Promise<string> {
    const response = await this.client.speechToText.convert({
      modelId: input.modelId,
      file: new Blob([Uint8Array.from(input.bytes)], {type: input.contentType}),
    });
    if (!("text" in response) || typeof response.text !== "string") {
      throw new Error("ElevenLabs hat keinen Text geliefert.");
    }
    return response.text.trim();
  }

  async synthesize(input: {voiceId: string; modelId: string; text: string}): Promise<Uint8Array> {
    const stream = await this.client.textToSpeech.convert(input.voiceId, {
      text: input.text, modelId: input.modelId, outputFormat: audioFormat,
    });
    return bytesFrom(stream);
  }
}

function voiceFrom(voice: {voiceId: string; name?: string; description?: string; category?: string; labels?: Record<string, string>}): ElevenLabsVoice {
  return {
    voiceId: voice.voiceId,
    name: voice.name ?? voice.voiceId,
    ...(voice.description ? {description: voice.description} : {}),
    ...(voice.category ? {category: voice.category} : {}),
    ...(voice.labels?.language ? {language: voice.labels.language} : {}),
  };
}

async function bytesFrom(stream: ReadableStream<Uint8Array>): Promise<Uint8Array> {
  const chunks: Uint8Array[] = [];
  const reader = stream.getReader();
  for (let result = await reader.read(); !result.done; result = await reader.read()) chunks.push(result.value);
  const bytes = new Uint8Array(chunks.reduce((total, chunk) => total + chunk.length, 0));
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  return bytes;
}
