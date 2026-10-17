import assert from "node:assert/strict";
import test from "node:test";
import {
  defaultGenerationOptions,
  generationOptionsFrom,
} from "../../../domain/entities/generation-options.js";
import {googleAiGenerationConfig} from "./google-ai-generation-config.js";
import {ollamaGenerationConfig} from "./ollama-generation-config.js";
import {openAiCompatibleGenerationConfig} from "./open-ai-compatible-generation-config.js";

const allOptions = generationOptionsFrom({temperature: 0.3, maxOutputTokens: 800, contextWindow: 16384, thinking: "off"});

test("model defaults send no configuration to any provider", () => {
  assert.deepEqual(ollamaGenerationConfig.configFor(defaultGenerationOptions), {});
  assert.deepEqual(googleAiGenerationConfig("gemini-2.5-flash").configFor(defaultGenerationOptions), {});
  assert.deepEqual(openAiCompatibleGenerationConfig.configFor(defaultGenerationOptions), {});
});

test("Ollama receives every option including the context window", () => {
  assert.deepEqual(ollamaGenerationConfig.configFor(allOptions), {
    temperature: 0.3, maxOutputTokens: 800, numCtx: 16384, think: false,
  });
  assert.deepEqual(ollamaGenerationConfig.configFor(generationOptionsFrom({thinking: "high"})), {think: "high"});
});

test("Gemini 2.5 controls thinking with a budget and ignores the context window", () => {
  const config = googleAiGenerationConfig("gemini-2.5-flash");

  assert.deepEqual(config.configFor(allOptions), {
    temperature: 0.3, maxOutputTokens: 800, thinkingConfig: {thinkingBudget: 0},
  });
  assert.deepEqual(config.configFor(generationOptionsFrom({thinking: "medium"})), {thinkingConfig: {thinkingBudget: 8192}});
});

test("Gemini 3 controls thinking with a level; Pro cannot go below LOW", () => {
  const off = generationOptionsFrom({thinking: "off"});

  assert.deepEqual(googleAiGenerationConfig("gemini-3.1-flash-lite").configFor(off), {thinkingConfig: {thinkingLevel: "MINIMAL"}});
  assert.deepEqual(googleAiGenerationConfig("gemini-3.1-pro-preview").configFor(off), {thinkingConfig: {thinkingLevel: "LOW"}});
  assert.deepEqual(
    googleAiGenerationConfig("gemini-3-flash").configFor(generationOptionsFrom({thinking: "high"})),
    {thinkingConfig: {thinkingLevel: "HIGH"}},
  );
});

test("OpenAI-compatible providers get max_tokens and reasoning_effort as pass-through fields", () => {
  assert.deepEqual(openAiCompatibleGenerationConfig.configFor(allOptions), {temperature: 0.3, max_tokens: 800});
  assert.deepEqual(
    openAiCompatibleGenerationConfig.configFor(generationOptionsFrom({thinking: "low"})),
    {reasoning_effort: "low"},
  );
});
