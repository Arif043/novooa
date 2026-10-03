import assert from "node:assert/strict";
import test from "node:test";
import {type LanguageModelCatalog} from "../../../language_models/domain/repositories/language-model-catalog.js";
import {defaultLanguageModelCapabilities, type LanguageModelProvider} from "../../../language_models/domain/entities/language-model.js";
import {SpeechSynthesisError} from "../entities/speech.js";
import {type SpeechProvider} from "../repositories/speech-provider.js";
import {LanguageModelSpeech} from "./language-model-speech.js";

function catalogFor(provider: LanguageModelProvider): LanguageModelCatalog {
  return {
    loadModel: async () => ({
      id: "m1", teamId: "t", connectionId: "c1", name: "TTS", modelId: "tts-model", capabilities: defaultLanguageModelCapabilities,
    }),
    loadConnection: async () => ({id: "c1", teamId: "t", name: "Verbindung", provider}),
    loadConnectionApiKey: async () => "secret",
  };
}

function providerFor(kind: LanguageModelProvider, calls: Array<{text: string; voiceId: string}>): SpeechProvider {
  return {
    supports: (candidate) => candidate === kind,
    maximumTextLength: 10,
    synthesize: async (_context, input) => {
      calls.push(input);
      return {bytes: new Uint8Array([1]), contentType: "audio/wav", fileExtension: "wav"};
    },
    listVoices: async () => ({voices: [{id: "a", name: "A"}], defaultVoiceId: "a", allowsCustomVoice: false}),
  };
}

test("uses the default voice when none is requested", async () => {
  const calls: Array<{text: string; voiceId: string}> = [];
  const speech = new LanguageModelSpeech(catalogFor("googleAi"), [providerFor("googleAi", calls)]);

  await speech.synthesize({teamId: "t", languageModelId: "m1", text: " Hallo "});

  assert.deepEqual(calls, [{text: "Hallo", voiceId: "a"}]);
});

test("passes a requested voice through", async () => {
  const calls: Array<{text: string; voiceId: string}> = [];
  const speech = new LanguageModelSpeech(catalogFor("googleAi"), [providerFor("googleAi", calls)]);

  await speech.synthesize({teamId: "t", languageModelId: "m1", text: "Hallo", voiceId: "Puck"});

  assert.equal(calls[0].voiceId, "Puck");
});

test("rejects empty and too long texts with readable errors", async () => {
  const speech = new LanguageModelSpeech(catalogFor("googleAi"), [providerFor("googleAi", [])]);

  await assert.rejects(speech.synthesize({teamId: "t", languageModelId: "m1", text: "  "}), /leer/);
  await assert.rejects(speech.synthesize({teamId: "t", languageModelId: "m1", text: "x".repeat(11)}), /zu lang.*10/);
});

test("rejects providers without speech support", async () => {
  const speech = new LanguageModelSpeech(catalogFor("ollama"), [providerFor("googleAi", [])]);

  await assert.rejects(
    speech.synthesize({teamId: "t", languageModelId: "m1", text: "Hallo"}),
    (error: unknown) => error instanceof SpeechSynthesisError && /keine Sprachausgabe/.test(error.message),
  );
});

test("lists voices of the matching provider", async () => {
  const speech = new LanguageModelSpeech(catalogFor("elevenLabs"), [providerFor("elevenLabs", [])]);

  const list = await speech.listVoices("t", "m1");

  assert.equal(list.defaultVoiceId, "a");
});
