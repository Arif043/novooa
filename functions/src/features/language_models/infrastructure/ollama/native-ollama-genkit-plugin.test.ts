import assert from "node:assert/strict";
import test from "node:test";
import {genkit, modelRef, z} from "genkit";
import {nativeOllamaPlugin} from "./native-ollama-genkit-plugin.js";
import {type NativeOllamaChatRequest} from "./native-ollama-chat-client.js";

test("registers Ollama as a Genkit model and forwards its JSON schema", async () => {
  let capturedRequest: NativeOllamaChatRequest | undefined;
  const ai = genkit({plugins: [nativeOllamaPlugin({
    name: "ollama-test",
    serverAddress: "http://ollama.test:11434",
    modelId: "gemma4:12b",
    chatClient: {
      async chat(request) {
        capturedRequest = request;
        return "{\"vendor\":\"PENNY\"}";
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
    additionalProperties: true,
    "\$schema": "http://json-schema.org/draft-07/schema#",
  });
});
