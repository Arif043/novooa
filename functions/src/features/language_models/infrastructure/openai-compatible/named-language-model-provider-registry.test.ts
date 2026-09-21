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
  ] as const;

  for (const [provider, baseUrl] of expectedProviders) {
    const configuration = namedLanguageModelProviderFor(provider);
    assert.equal(configuration?.baseUrl, baseUrl);
    assert.deepEqual(configuration?.discoverModels({
      data: [{id: "provider/model", name: "Anzeigename"}],
    }).map((model) => model.modelId), ["provider/model"]);
  }
});
