import assert from "node:assert/strict";
import test from "node:test";
import {
  namedLanguageModelProviderFor,
} from "./named-language-model-provider-registry.js";

test("defines fixed OpenAI-compatible endpoints for supported cloud providers", () => {
  const expectedProviders = [
    ["xAi", "https://api.x.ai/v1"],
    ["mistral", "https://api.mistral.ai/v1"],
    ["openRouter", "https://openrouter.ai/api/v1"],
    ["abacus", "https://routellm.abacus.ai/v1"],
    ["huggingFace", "https://router.huggingface.co/v1"],
  ] as const;

  for (const [provider, baseUrl] of expectedProviders) {
    const configuration = namedLanguageModelProviderFor(provider);
    assert.equal(configuration?.baseUrl, baseUrl);
    assert.ok(
      configuration?.discoverModels({
        data: [{id: "provider/model", name: "Anzeigename"}],
      }).some((model) => model.modelId === "provider/model"),
      provider,
    );
  }
});

test("Abacus und Hugging Face erscheinen getrennt von generischen OpenAI-kompatiblen Anbietern", () => {
  assert.equal(namedLanguageModelProviderFor("abacus")?.displayName, "Abacus.AI (RouteLLM)");
  assert.equal(namedLanguageModelProviderFor("huggingFace")?.displayName, "Hugging Face");
  assert.equal(namedLanguageModelProviderFor("openAiCompatible"), undefined);
});
