import assert from "node:assert/strict";
import test from "node:test";
import {genkit, modelRef, z} from "genkit";
import {nativeOllamaPlugin} from "./native-ollama-genkit-plugin.js";
import {type NativeOllamaChatRequest, type NativeOllamaChatResponse} from "./native-ollama-chat-client.js";
import {ModelEmptyResponseError, ModelResponseTruncatedError} from "../errors/language-model-errors.js";

test("registers Ollama as a Genkit model and forwards its JSON schema", async () => {
  let capturedRequest: NativeOllamaChatRequest | undefined;
  const ai = genkit({plugins: [nativeOllamaPlugin({
    name: "ollama-test",
    serverAddress: "http://ollama.test:11434",
    modelId: "gemma4:12b",
    chatClient: {
      async chat(request) {
        capturedRequest = request;
        return {content: "{\"vendor\":\"PENNY\"}", thinking: "", doneReason: "stop"};
      },
    },
  })]});

  const response = await ai.generate({
    model: modelRef({name: "ollama-test/gemma4:12b"}),
    prompt: "Lies den Handler.",
    output: {schema: z.object({vendor: z.string()})},
  });

  assert.deepEqual(response.output, {vendor: "PENNY"});
  assert.equal(capturedRequest?.baseUrl, "http://ollama.test:11434");
  assert.equal(capturedRequest?.modelId, "gemma4:12b");
  assert.match(capturedRequest?.messages[0]?.content ?? "", /Lies den Handler./);
  assert.deepEqual(capturedRequest?.format, {
    type: "object",
    properties: {vendor: {type: "string"}},
    required: ["vendor"],
    additionalProperties: false,
    "\$schema": "http://json-schema.org/draft-07/schema#",
  });
});

test("forwards Genkit config as Ollama options and thinking", async () => {
  let capturedRequest: NativeOllamaChatRequest | undefined;
  const ai = ollamaAi(async (request) => {
    capturedRequest = request;
    return {content: "Hallo", thinking: "", doneReason: "stop"};
  });

  await ai.generate({
    model: modelRef({name: "ollama-test/qwen3-vl:8b"}),
    prompt: "Hallo",
    config: {numCtx: 16384, maxOutputTokens: 400, temperature: 0, think: false},
  });

  assert.deepEqual(capturedRequest?.options, {
    num_ctx: 16384, num_predict: 400, temperature: 0, top_k: undefined, top_p: undefined, stop: undefined,
  });
  assert.equal(capturedRequest?.think, false);
});

test("fails with our truncation error before Genkit validates the schema", async () => {
  const ai = ollamaAi(async () => ({content: "", thinking: "Ich lese den Bon …", doneReason: "length"}));

  await assert.rejects(
    ai.generate({
      model: modelRef({name: "ollama-test/qwen3-vl:8b"}),
      prompt: "Lies den Bon.",
      output: {schema: z.object({vendor: z.string()})},
    }),
    (error: unknown) => error instanceof ModelResponseTruncatedError && /Nachdenken/.test(error.message),
  );
});

test("fails with our empty-response error when the model only thought", async () => {
  const ai = ollamaAi(async () => ({content: " ", thinking: "…", doneReason: "stop"}));

  await assert.rejects(
    ai.generate({model: modelRef({name: "ollama-test/qwen3-vl:8b"}), prompt: "Hallo"}),
    ModelEmptyResponseError,
  );
});

test("keeps deliberately truncated free text and reports the finish reason", async () => {
  const ai = ollamaAi(async () => ({content: "Ein langer Te", thinking: "", doneReason: "length"}));

  const response = await ai.generate({model: modelRef({name: "ollama-test/qwen3-vl:8b"}), prompt: "Schreib."});

  assert.equal(response.text, "Ein langer Te");
  assert.equal(response.finishReason, "length");
});

function ollamaAi(chat: (request: NativeOllamaChatRequest) => Promise<NativeOllamaChatResponse>) {
  return genkit({plugins: [nativeOllamaPlugin({
    name: "ollama-test",
    serverAddress: "http://ollama.test:11434",
    modelId: "qwen3-vl:8b",
    chatClient: {chat},
  })]});
}
