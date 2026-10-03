import assert from "node:assert/strict";
import test from "node:test";
import {defaultLanguageModelCapabilities, type LanguageModelProvider} from "../../language_models/domain/entities/language-model.js";
import {type ElevenLabsApi} from "../../language_models/infrastructure/elevenlabs/elevenlabs-api.js";
import {type AudioInput} from "../domain/entities/transcription.js";
import {type TranscriptionProviderContext} from "../domain/repositories/transcription-provider.js";
import {LanguageModelTranscription} from "../domain/usecases/language-model-transcription.js";
import {defaultTranscriptionProviders} from "./default-transcription-providers.js";
import {ElevenLabsTranscriptionProvider} from "./elevenlabs/elevenlabs-transcription-provider.js";
import {GoogleTranscriptionProvider} from "./google/google-transcription-provider.js";
import {OpenAiCompatibleTranscriptionProvider} from "./openai/openai-compatible-transcription-provider.js";

const audio: AudioInput = {bytes: new Uint8Array([1, 2, 3]), contentType: "audio/wav", displayName: "a.wav"};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {status});

function contextFor(provider: LanguageModelProvider, baseUrl?: string): TranscriptionProviderContext {
  return {
    connection: {id: "c", teamId: "t", name: "Dienst", provider, baseUrl},
    model: {id: "m", teamId: "t", connectionId: "c", name: "M", modelId: "stt-model", capabilities: defaultLanguageModelCapabilities},
    apiKey: "key",
  };
}

test("Google sends the audio inline to generateContent and joins the text parts", async () => {
  let sent: {url: string; body: any} | undefined;
  const provider = new GoogleTranscriptionProvider((async (url: string, init: RequestInit) => {
    sent = {url, body: JSON.parse(String(init.body))};
    return json({candidates: [{content: {parts: [{text: "Hallo "}, {text: "Welt"}]}}]});
  }) as unknown as typeof fetch);

  const text = await provider.transcribe(contextFor("googleAi"), audio);

  assert.match(sent!.url, /models\/stt-model:generateContent$/);
  assert.equal(sent!.body.contents[0].parts[1].inline_data.mime_type, "audio/wav");
  assert.equal(sent!.body.contents[0].parts[1].inline_data.data, Buffer.from([1, 2, 3]).toString("base64"));
  assert.equal(text, "Hallo Welt");
});

test("Google reports empty answers and API errors readably", async () => {
  const empty = new GoogleTranscriptionProvider(async () => json({candidates: []}));
  const denied = new GoogleTranscriptionProvider(async () => json({error: {message: "quota"}}, 429));

  await assert.rejects(empty.transcribe(contextFor("googleAi"), audio), /keinen Text/);
  await assert.rejects(denied.transcribe(contextFor("googleAi"), audio), /429.*quota/);
});

test("OpenAI-compatible posts multipart to /audio/transcriptions", async () => {
  let sent: {url: string; auth: string; form: FormData} | undefined;
  const provider = new OpenAiCompatibleTranscriptionProvider((async (url: string, init: RequestInit) => {
    sent = {url, auth: (init.headers as Record<string, string>).authorization, form: init.body as FormData};
    return json({text: " Hallo "});
  }) as unknown as typeof fetch);

  const text = await provider.transcribe(contextFor("openAiCompatible", "https://x.test/v1/"), audio);

  assert.equal(sent!.url, "https://x.test/v1/audio/transcriptions");
  assert.equal(sent!.auth, "Bearer key");
  assert.equal(sent!.form.get("model"), "stt-model");
  assert.equal((sent!.form.get("file") as File).name, "a.wav");
  assert.equal(text, "Hallo");
});

test("OpenAI-compatible explains rejections", async () => {
  const provider = new OpenAiCompatibleTranscriptionProvider(async () => json({error: {message: "no endpoint"}}, 404));

  await assert.rejects(provider.transcribe(contextFor("openAiCompatible", "https://x.test/v1"), audio), /404.*no endpoint/);
});

function elevenLabsApi(transcribe: ElevenLabsApi["transcribe"]): () => ElevenLabsApi {
  return () => ({listSpeechModels: async () => [], listVoices: async () => [], synthesize: async () => new Uint8Array(), transcribe});
}

test("ElevenLabs transcribes with the chosen Scribe model and wraps SDK errors", async () => {
  let received: unknown;
  const ok = new ElevenLabsTranscriptionProvider(elevenLabsApi(async (input) => { received = input; return "Hallo"; }));
  const failing = new ElevenLabsTranscriptionProvider(elevenLabsApi(async () => { throw Object.assign(new Error("bad key\nmore"), {statusCode: 401}); }));

  assert.equal(await ok.transcribe(contextFor("elevenLabs"), audio), "Hallo");
  assert.deepEqual(received, {modelId: "stt-model", bytes: audio.bytes, contentType: "audio/wav"});
  await assert.rejects(failing.transcribe(contextFor("elevenLabs"), audio), /\(401\): bad key$/);
});

test("the provider order maps each connection kind to exactly one adapter", () => {
  const providers = defaultTranscriptionProviders();
  const pick = (kind: LanguageModelProvider) => providers.find((candidate) => candidate.supports(kind));

  assert.ok(pick("googleAi") instanceof GoogleTranscriptionProvider);
  assert.ok(pick("elevenLabs") instanceof ElevenLabsTranscriptionProvider);
  assert.ok(pick("mistral") instanceof OpenAiCompatibleTranscriptionProvider);
  assert.equal(pick("ollama"), undefined);
});

test("the use case rejects non-audio files, unsupported providers and oversized files", async () => {
  const catalog = (provider: LanguageModelProvider) => ({
    loadModel: async () => ({id: "m", teamId: "t", connectionId: "c", modelId: "x"}),
    loadConnection: async () => ({id: "c", teamId: "t", name: "Dienst", provider}),
    loadConnectionApiKey: async () => "key",
  }) as never;
  const request = (file: AudioInput) => ({teamId: "t", languageModelId: "m", audio: file});

  const google = new LanguageModelTranscription(catalog("googleAi"), defaultTranscriptionProviders());
  const ollama = new LanguageModelTranscription(catalog("ollama"), defaultTranscriptionProviders());

  await assert.rejects(google.transcribe(request({...audio, contentType: "text/plain"})), /keine Audiodatei/);
  await assert.rejects(ollama.transcribe(request(audio)), /keine Transkription/);
  await assert.rejects(google.transcribe(request({...audio, bytes: new Uint8Array(15 * 1024 * 1024)})), /zu groß.*14 MB/);
});
