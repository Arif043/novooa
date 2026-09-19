import assert from "node:assert/strict";
import test from "node:test";
import {NativeOllamaChatClient} from "./native-ollama-chat-client.js";

test("uses Ollama's native chat API with images and a schema format", async () => {
  let calledUrl = "";
  let requestBody: Record<string, unknown> | undefined;
  const client = new NativeOllamaChatClient(async (url, init) => {
    calledUrl = String(url);
    requestBody = JSON.parse(String(init?.body)) as Record<string, unknown>;
    return new Response(JSON.stringify({message: {content: '{"name":"PENNY"}'}}));
  });

  const response = await client.chat({
    baseUrl: "http://host.docker.internal:11434/v1",
    modelId: "gemma4:12b",
    messages: [{
      role: "user", content: "Lies den Beleg.", mediaUrls: ["data:image/png;base64,aW1hZ2U="],
    }],
    format: {type: "object"},
  });

  assert.equal(calledUrl, "http://host.docker.internal:11434/api/chat");
  assert.equal(response, '{"name":"PENNY"}');
  assert.deepEqual(requestBody, {
    model: "gemma4:12b",
    messages: [{role: "user", content: "Lies den Beleg.", images: ["aW1hZ2U="]}],
    stream: false,
    format: {type: "object"},
  });
});

test("rejects media that Ollama cannot receive as an image", async () => {
  const client = new NativeOllamaChatClient(async () => new Response());

  await assert.rejects(
    client.chat({
      baseUrl: "http://localhost:11434/v1",
      modelId: "gemma4:12b",
      messages: [{
        role: "user", content: "Test", mediaUrls: ["https://example.test/image.png"],
      }],
    }),
    /Data-URL/,
  );
});
