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
          imageGeneration: false,
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
      imageGeneration: false,
    },
  };
}

test("an Ollama model takes its tool calling from what Ollama reports", async () => {
  const capabilities = {textGeneration: true, imageInput: false, structuredOutput: true, toolCalling: false, imageGeneration: false};
  const resolver = new CatalogGenkitLanguageModelResolver({
    loadModel: async () => ({id: "m", teamId: "t", connectionId: "c", name: "Qwen", modelId: "qwen3", capabilities}),
    loadConnection: async () => ({id: "c", teamId: "t", name: "Ollama", provider: "ollama" as const, baseUrl: "http://127.0.0.1:11434/v1"}),
    loadConnectionApiKey: async () => "",
  }, {inspect: async (input: {fallback: typeof capabilities}) => ({...input.fallback, toolCalling: true})} as never);

  const model = await resolver.resolve("t", "m");

  assert.equal(model.capabilities.toolCalling, true);
  assert.equal(model.capabilities.structuredOutput, true);
});
