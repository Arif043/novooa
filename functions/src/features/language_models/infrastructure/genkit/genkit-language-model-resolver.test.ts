import assert from "node:assert/strict";
import test from "node:test";
import {CatalogGenkitLanguageModelResolver} from "./genkit-language-model-resolver.js";

test("resolves an OpenAI-compatible team model with its own endpoint", async () => {
  const resolver = new CatalogGenkitLanguageModelResolver({
    async loadModel() {
      return {
        id: "model-1",
        teamId: "team-1",
        connectionId: "connection-1",
        name: "Lokales Modell",
        modelId: "qwen3",
        capabilities: {
          textGeneration: true,
          imageInput: false,
          structuredOutput: true,
          toolCalling: false,
          imageGeneration: false, speechSynthesis: false,
        },
      };
    },
    async loadConnection() {
      return {
        id: "connection-1",
        teamId: "team-1",
        name: "vLLM",
        provider: "openAiCompatible" as const,
        baseUrl: "https://models.example.test/v1",
      };
    },
    async loadConnectionApiKey() {
      return "test-key";
    },
  });

  const model = await resolver.resolve("team-1", "model-1");

  assert.deepEqual(model.logContext, {
    provider: "openAiCompatible",
    endpoint: "vLLM",
    model: "qwen3",
  });
  assert.equal(model.capabilities.structuredOutput, true);
});

test("resolves xAI through its registered OpenAI-compatible endpoint", async () => {
  const resolver = new CatalogGenkitLanguageModelResolver({
    async loadModel() {
      return modelFor("connection-1");
    },
    async loadConnection() {
      return {
        id: "connection-1",
        teamId: "team-1",
        name: "xAI (Grok)",
        provider: "xAi" as const,
      };
    },
    async loadConnectionApiKey() {
      return "customer-api-key";
    },
  });

  const model = await resolver.resolve("team-1", "model-1");

  assert.deepEqual(model.logContext, {
    provider: "xAi",
    endpoint: "xAI (Grok)",
    model: "grok-4",
  });
});

function modelFor(connectionId: string) {
  return {
    id: "model-1",
    teamId: "team-1",
    connectionId,
    name: "Grok 4",
    modelId: "grok-4",
    capabilities: {
      textGeneration: true,
      imageInput: false,
      structuredOutput: true,
      toolCalling: false,
      imageGeneration: false, speechSynthesis: false,
    },
  };
}
