import assert from "node:assert/strict";
import test from "node:test";
import {discoverElevenLabsModels} from "./elevenlabs-language-model-provider.js";
import {type ElevenLabsApi} from "./elevenlabs-api.js";

function apiWith(models: Array<{modelId: string; name: string}>): ElevenLabsApi {
  return {
    listSpeechModels: async () => models,
    listVoices: async () => [],
    synthesize: async () => new Uint8Array(),
  };
}

test("alle Sprachmodelle des Kontos werden angeboten", async () => {
  const models = await discoverElevenLabsModels(apiWith([
    {modelId: "eleven_multilingual_v2", name: "Eleven Multilingual v2"},
    {modelId: "eleven_flash_v2_5", name: "Eleven Flash v2.5"},
  ]));

  assert.deepEqual(models.map((model) => [model.modelId, model.name]), [
    ["eleven_multilingual_v2", "Eleven Multilingual v2"],
    ["eleven_flash_v2_5", "Eleven Flash v2.5"],
  ]);
});

test("ein Konto ohne Sprachmodelle liefert eine leere Liste", async () => {
  assert.deepEqual(await discoverElevenLabsModels(apiWith([])), []);
});
