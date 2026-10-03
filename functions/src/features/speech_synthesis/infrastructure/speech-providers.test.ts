import assert from "node:assert/strict";
import test from "node:test";
import {defaultLanguageModelCapabilities, type LanguageModelProvider} from "../../language_models/domain/entities/language-model.js";
import {type ElevenLabsApi} from "../../language_models/infrastructure/elevenlabs/elevenlabs-api.js";
import {type SpeechProviderContext} from "../domain/repositories/speech-provider.js";
import {ElevenLabsSpeechProvider} from "./elevenlabs/elevenlabs-speech-provider.js";
import {GoogleSpeechProvider, googlePrebuiltVoices} from "./google/google-speech-provider.js";
import {OpenAiCompatibleSpeechProvider} from "./openai/openai-compatible-speech-provider.js";
import {defaultSpeechProviders} from "./default-speech-providers.js";

function contextFor(provider: LanguageModelProvider, baseUrl?: string): SpeechProviderContext {
  return {
    connection: {id: "c", teamId: "t", name: "Dienst", provider, baseUrl},
    model: {id: "m", teamId: "t", connectionId: "c", name: "TTS", modelId: "tts-model", capabilities: defaultLanguageModelCapabilities},
    apiKey: "key",
  };
}

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {status});

test("Google sends a WAV interaction with the chosen voice and decodes the audio", async () => {
  let sent: {url: string; body: Record<string, unknown>} | undefined;
  const provider = new GoogleSpeechProvider((async (url: string, init: RequestInit) => {
    sent = {url, body: JSON.parse(String(init.body))};
    return json({steps: [{type: "model_output", content: [{type: "audio", data: Buffer.from("RIFF").toString("base64")}]}]});
  }) as unknown as typeof fetch);

  const speech = await provider.synthesize(contextFor("googleAi"), {text: "Hallo", voiceId: "Puck"});

  assert.match(sent!.url, /\/v1beta\/interactions$/);
  assert.equal(sent!.body.model, "tts-model");
  assert.deepEqual(sent!.body.generation_config, {speech_config: [{voice: "Puck"}]});
  assert.equal(Buffer.from(speech.bytes).toString(), "RIFF");
  assert.equal(speech.contentType, "audio/wav");
});

test("Google wraps raw PCM answers of older TTS models into a playable WAV and sends no format request", async () => {
  let body: Record<string, unknown> = {};
  const pcm = Buffer.from([1, 2, 3, 4]).toString("base64");
  const provider = new GoogleSpeechProvider((async (_url: string, init: RequestInit) => {
    body = JSON.parse(String(init.body));
    return json({steps: [{type: "model_output", content: [{type: "audio", mime_type: "audio/L16;rate=24000", data: pcm}]}]});
  }) as unknown as typeof fetch);

  const speech = await provider.synthesize(contextFor("googleAi"), {text: "Hallo", voiceId: "Kore"});

  assert.deepEqual(body.response_format, {type: "audio"});
  assert.equal(Buffer.from(speech.bytes.slice(0, 4)).toString(), "RIFF");
  assert.equal(speech.bytes.length, 48);
  assert.equal(Buffer.from(speech.bytes).readUInt32LE(24), 24000);
  assert.equal(speech.contentType, "audio/wav");
});

test("Google reports a missing audio part and API errors readably", async () => {
  const empty = new GoogleSpeechProvider(async () => json({steps: []}));
  const denied = new GoogleSpeechProvider(async () => json({error: {message: "API key not valid"}}, 400));

  await assert.rejects(empty.synthesize(contextFor("googleAi"), {text: "x", voiceId: "Kore"}), /keine Audiodaten/);
  await assert.rejects(denied.synthesize(contextFor("googleAi"), {text: "x", voiceId: "Kore"}), /400.*API key not valid/);
});

test("Google lists the fetched voices sorted by name without duplicates", async () => {
  const provider = new GoogleSpeechProvider(async () => json({voices: [
    {id: "Zeta", display_name: "Zeta", language_code: "de-DE"},
    {id: "Alpha", display_name: "Alpha"},
    {id: "Zeta", display_name: "Zeta"},
  ]}));

  const list = await provider.listVoices(contextFor("googleAi"));

  assert.deepEqual(list.voices.map((voice) => voice.id), ["Alpha", "Zeta"]);
  assert.equal(list.defaultVoiceId, "Alpha");
});

test("Google falls back to the studio voices when the voice library fails", async () => {
  const provider = new GoogleSpeechProvider(async () => { throw new Error("offline"); });

  const list = await provider.listVoices(contextFor("googleAi"));

  assert.equal(list.voices.length, googlePrebuiltVoices.length);
  assert.equal(list.defaultVoiceId, "Kore");
});

test("OpenAI-compatible posts to /audio/speech of the connection and returns mp3", async () => {
  let sent: {url: string; headers: Record<string, string>; body: Record<string, unknown>} | undefined;
  const provider = new OpenAiCompatibleSpeechProvider((async (url: string, init: RequestInit) => {
    sent = {url, headers: init.headers as Record<string, string>, body: JSON.parse(String(init.body))};
    return new Response(new Uint8Array([1, 2, 3]));
  }) as unknown as typeof fetch);

  const speech = await provider.synthesize(contextFor("openAiCompatible", "https://api.example.com/v1/"), {text: "Hallo", voiceId: "nova"});

  assert.equal(sent!.url, "https://api.example.com/v1/audio/speech");
  assert.equal(sent!.headers.authorization, "Bearer key");
  assert.deepEqual(sent!.body, {model: "tts-model", input: "Hallo", voice: "nova", response_format: "mp3"});
  assert.deepEqual([...speech.bytes], [1, 2, 3]);
  assert.equal(speech.fileExtension, "mp3");
});

test("OpenAI-compatible explains rejections and offers custom voices", async () => {
  const provider = new OpenAiCompatibleSpeechProvider(async () => json({error: {message: "no such endpoint"}}, 404));

  await assert.rejects(provider.synthesize(contextFor("openAiCompatible", "https://x.test/v1"), {text: "x", voiceId: "alloy"}), /404.*no such endpoint/);
  const list = await provider.listVoices();
  assert.equal(list.allowsCustomVoice, true);
  assert.equal(list.defaultVoiceId, "alloy");
});

test("the speech provider order maps each connection kind to exactly one adapter", () => {
  const providers = defaultSpeechProviders();
  const pick = (kind: LanguageModelProvider) => providers.find((candidate) => candidate.supports(kind));

  assert.ok(pick("googleAi") instanceof GoogleSpeechProvider);
  assert.ok(pick("elevenLabs") instanceof ElevenLabsSpeechProvider);
  for (const kind of ["openAiCompatible", "mistral", "xAi", "openRouter", "abacus", "huggingFace"] as const) {
    assert.ok(pick(kind) instanceof OpenAiCompatibleSpeechProvider, kind);
  }
  assert.equal(pick("ollama"), undefined);
});

function elevenLabsApi(overrides: Partial<ElevenLabsApi>): () => ElevenLabsApi {
  return () => ({
    listSpeechModels: async () => [], listVoices: async () => [], synthesize: async () => new Uint8Array([9]), transcribe: async () => "", ...overrides,
  });
}

test("ElevenLabs lists account voices and uses the first as default", async () => {
  const provider = new ElevenLabsSpeechProvider(elevenLabsApi({
    listVoices: async () => [{voiceId: "v1", name: "Rachel", language: "en"}, {voiceId: "v2", name: "Hans"}],
  }));

  const list = await provider.listVoices(contextFor("elevenLabs"));

  assert.equal(list.defaultVoiceId, "v1");
  assert.deepEqual(list.voices.map((voice) => voice.name), ["Rachel", "Hans"]);
});

test("ElevenLabs synthesizes with model and voice and wraps SDK errors", async () => {
  let received: unknown;
  const ok = new ElevenLabsSpeechProvider(elevenLabsApi({synthesize: async (input) => { received = input; return new Uint8Array([9]); }}));
  const failing = new ElevenLabsSpeechProvider(elevenLabsApi({synthesize: async () => { throw Object.assign(new Error("quota exceeded\nmore"), {statusCode: 401}); }}));

  const speech = await ok.synthesize(contextFor("elevenLabs"), {text: "Hallo", voiceId: "v1"});

  assert.deepEqual(received, {voiceId: "v1", modelId: "tts-model", text: "Hallo"});
  assert.equal(speech.contentType, "audio/mpeg");
  await assert.rejects(failing.synthesize(contextFor("elevenLabs"), {text: "x", voiceId: "v1"}), /\(401\): quota exceeded$/);
});
