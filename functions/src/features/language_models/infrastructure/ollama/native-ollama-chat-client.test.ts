import assert from "node:assert/strict";
import test from "node:test";
import {NativeOllamaChatClient} from "./native-ollama-chat-client.js";
import {
  ModelProviderUnavailableError,
  ModelRequestRejectedError,
  ModelTimeoutError,
} from "../errors/language-model-errors.js";

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
  assert.deepEqual(response, {content: '{"name":"PENNY"}', thinking: "", doneReason: "stop", toolCalls: []});
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
    ModelRequestRejectedError,
  );
});

test("sends runtime options and thinking, and reports why Ollama stopped", async () => {
  let requestBody: Record<string, unknown> | undefined;
  const client = new NativeOllamaChatClient(async (_url, init) => {
    requestBody = JSON.parse(init?.body as string) as Record<string, unknown>;
    return new Response(JSON.stringify({message: {content: "", thinking: "Hmm …"}, done_reason: "length"}));
  });

  const response = await client.chat({
    baseUrl: "http://localhost:11434", modelId: "qwen3-vl:8b",
    messages: [{role: "user", content: "Lies den Bon.", mediaUrls: []}],
    options: {num_ctx: 16384, num_predict: undefined, temperature: 0},
    think: false,
  });

  assert.deepEqual(requestBody?.options, {num_ctx: 16384, temperature: 0});
  assert.equal(requestBody?.think, false);
  assert.deepEqual(response, {content: "", thinking: "Hmm …", doneReason: "length", toolCalls: []});
});

test("omits options when every value is left to the model", async () => {
  let requestBody: Record<string, unknown> | undefined;
  const client = new NativeOllamaChatClient(async (_url, init) => {
    requestBody = JSON.parse(init?.body as string) as Record<string, unknown>;
    return new Response(JSON.stringify({message: {content: "ok"}}));
  });

  await client.chat({baseUrl: "http://localhost:11434", modelId: "m", messages: [], options: {num_ctx: undefined}});

  assert.equal("options" in (requestBody ?? {}), false);
  assert.equal("think" in (requestBody ?? {}), false);
});

test("throws our errors for server errors, rejected requests, timeouts and unreachable hosts", async () => {
  const chat = (respond: () => Promise<Response>) => new NativeOllamaChatClient(respond)
    .chat({baseUrl: "http://localhost:11434", modelId: "m", messages: []});
  const timeout = Object.assign(new Error("aborted"), {name: "TimeoutError"});

  await assert.rejects(chat(async () => new Response("boom", {status: 500})), ModelProviderUnavailableError);
  await assert.rejects(chat(async () => new Response("model not found", {status: 404})), ModelRequestRejectedError);
  await assert.rejects(chat(async () => { throw timeout; }), ModelTimeoutError);
  await assert.rejects(chat(async () => { throw new TypeError("fetch failed"); }), ModelProviderUnavailableError);
});

test("sends tools and earlier tool calls and reads the model's tool calls", async () => {
  let requestBody: Record<string, unknown> | undefined;
  const client = new NativeOllamaChatClient(async (_url, init) => {
    requestBody = JSON.parse(init?.body as string) as Record<string, unknown>;
    return new Response(JSON.stringify({message: {content: "", tool_calls: [
      {function: {name: "delegate", arguments: {task: "A"}}},
      {function: {name: "read_file", arguments: "{\"path\":\"a.md\"}"}},
    ]}}));
  });
  const tool = {type: "function" as const, function: {name: "delegate", description: "Vergibt", parameters: {type: "object"}}};

  const response = await client.chat({baseUrl: "http://localhost:11434", modelId: "gemma4:e4b", tools: [tool], messages: [
    {role: "assistant", content: "", mediaUrls: [], toolCalls: [{name: "delegate", arguments: {task: "B"}}]},
    {role: "tool", content: "\"erledigt\"", mediaUrls: [], toolName: "delegate"},
  ]});

  assert.deepEqual(requestBody?.tools, [tool]);
  assert.deepEqual(requestBody?.messages, [
    {role: "assistant", content: "", tool_calls: [{function: {name: "delegate", arguments: {task: "B"}}}]},
    {role: "tool", content: "\"erledigt\"", tool_name: "delegate"},
  ]);
  assert.deepEqual(response.toolCalls, [
    {name: "delegate", arguments: {task: "A"}},
    {name: "read_file", arguments: {path: "a.md"}},
  ]);
});
