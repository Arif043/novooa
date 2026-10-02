import assert from "node:assert/strict";
import test from "node:test";
import {discoverHuggingFaceLanguageModels} from "./huggingface-language-model-provider.js";

const router = {
  data: [
    {
      id: "deepseek-ai/DeepSeek-V4-Pro",
      architecture: {input_modalities: ["text"], output_modalities: ["text"]},
      providers: [
        {provider: "novita", status: "live", supports_tools: true, supports_structured_output: false},
        {provider: "together", status: "live", supports_tools: true, supports_structured_output: true},
      ],
    },
    {
      id: "Qwen/Qwen2-VL-72B-Instruct",
      architecture: {input_modalities: ["text", "image"], output_modalities: ["text"]},
      providers: [{provider: "nscale", status: "live"}],
    },
    {id: "org/ausgefallen", providers: [{provider: "x", status: "error"}]},
    {id: "org/ohne-provider-angaben"},
    {object: "model"},
    "kaputt",
  ],
};

test("liest Modelle aus dem Router und überspringt Modelle ohne aktiven Provider", () => {
  const models = discoverHuggingFaceLanguageModels(router);

  assert.deepEqual(models.map((model) => model.modelId), [
    "deepseek-ai/DeepSeek-V4-Pro",
    "Qwen/Qwen2-VL-72B-Instruct",
    "org/ohne-provider-angaben",
  ]);
});

test("Fähigkeiten folgen den aktiven Providern und Modalitäten", () => {
  const [text, vision, unknown] = discoverHuggingFaceLanguageModels(router);

  assert.equal(text.capabilities.toolCalling, true);
  assert.equal(text.capabilities.structuredOutput, true, "ein Provider unterstützt es");
  assert.equal(text.capabilities.imageInput, false);
  assert.equal(vision.capabilities.imageInput, true);
  assert.equal(vision.capabilities.toolCalling, false);
  assert.equal(vision.capabilities.structuredOutput, false, "Provider meldet keine Unterstützung");
  assert.equal(unknown.capabilities.structuredOutput, true, "ohne Angaben gilt der Standard");
  assert.equal(unknown.capabilities.toolCalling, false);
});

test("eine ungültige Antwort liefert keine Modelle", () => {
  for (const value of [null, {}, {data: "kaputt"}, "text"]) {
    assert.deepEqual(discoverHuggingFaceLanguageModels(value), []);
  }
});

test("Bildmodelle werden als solche erkannt", () => {
  const [model] = discoverHuggingFaceLanguageModels({
    data: [{id: "black-forest-labs/FLUX", architecture: {output_modalities: ["image"]}, providers: [{status: "live"}]}],
  });

  assert.equal(model.capabilities.imageGeneration, true);
});
