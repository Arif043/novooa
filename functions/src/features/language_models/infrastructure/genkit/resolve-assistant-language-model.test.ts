import assert from "node:assert/strict";
import test from "node:test";
import {resolveAssistantLanguageModel} from "./resolve-assistant-language-model.js";

process.env.GEMINI_API_KEY ??= "test-key";

test("ohne hinterlegtes Modell gilt das Standardmodell", async () => {
  const fromDefault = await resolveAssistantLanguageModel();
  const fromEmpty = await resolveAssistantLanguageModel({modelName: async () => null});

  assert.equal(JSON.stringify(fromEmpty.model), JSON.stringify(fromDefault.model));
});

test("ein in Remote Config hinterlegtes Google-Modell wird verwendet", async () => {
  const resolved = await resolveAssistantLanguageModel({modelName: async () => "gemini-2.5-flash"});

  assert.match(JSON.stringify(resolved.model), /gemini-2\.5-flash/);
});
