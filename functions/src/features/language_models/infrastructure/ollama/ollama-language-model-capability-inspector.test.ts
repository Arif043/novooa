import assert from "node:assert/strict";
import test from "node:test";
import {defaultLanguageModelCapabilities} from "../../domain/entities/language-model.js";
import {OllamaLanguageModelCapabilityInspector} from "./ollama-language-model-capability-inspector.js";

const inspect = (body: unknown) => new OllamaLanguageModelCapabilityInspector(async () => new Response(JSON.stringify(body)))
  .inspect({baseUrl: "http://localhost:11434/v1", modelId: "gemma4:e4b", fallback: defaultLanguageModelCapabilities});

test("reads image input and tool calling from Ollama's model capabilities", async () => {
  const capabilities = await inspect({capabilities: ["completion", "vision", "tools"]});

  assert.equal(capabilities.imageInput, true);
  assert.equal(capabilities.toolCalling, true);
});

test("a model without tools in its capabilities cannot call tools", async () => {
  const capabilities = await inspect({capabilities: ["completion"]});

  assert.equal(capabilities.toolCalling, false);
});
