import assert from "node:assert/strict";
import test from "node:test";
import {
  capabilitiesFromRecord,
  isSpeechModelId,
  languageModelProviders,
} from "./language-model.js";

test("erkennt reine Sprachmodelle an ihrer ID", () => {
  for (const id of ["gemini-3.8-flash-tts", "gemini-2.5-flash-preview-tts", "gpt-4o-mini-tts", "tts-1", "tts-1-hd", "openai/tts-1", "google:text-to-speech"]) {
    assert.equal(isSpeechModelId(id), true, id);
  }
});

test("normale Textmodelle gelten nicht als Sprachmodelle", () => {
  for (const id of ["gpt-4o", "gemini-2.5-flash", "mistral-small", "settings-model", "outstanding-1", "route-llm", "llama-3.3-70b"]) {
    assert.equal(isSpeechModelId(id), false, id);
  }
});

test("Fähigkeiten werden nur bei echtem true übernommen", () => {
  const parsed = capabilitiesFromRecord({structuredOutput: "true", textGeneration: 1, imageInput: true});

  assert.equal(parsed.structuredOutput, false);
  assert.equal(parsed.textGeneration, false);
  assert.equal(parsed.imageInput, true);
});

test("ElevenLabs ist ein eigener Anbieter", () => {
  assert.ok(languageModelProviders.includes("elevenLabs"));
});
