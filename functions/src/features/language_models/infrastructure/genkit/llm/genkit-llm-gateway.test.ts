import assert from "node:assert/strict";
import test from "node:test";
import {GenkitError} from "genkit";
import {PromptBuilder} from "../../../domain/prompting/prompt-builder.js";
import {type LlmOutputSpec} from "../../../domain/prompting/llm-gateway.js";
import {ModelProviderUnavailableError} from "../../errors/language-model-errors.js";
import {type GenkitLlmBinding} from "./genkit-llm-binding.js";
import {type LlmCallFinished, type LlmCallLog, type LlmCallStarted} from "./llm-call-log.js";
import {createLlmGateway} from "./llm-gateway-factory.js";

type GenerateOptions = {system?: string; messages?: unknown; prompt: unknown; output?: {schema?: unknown}; config?: unknown};

const prompt = PromptBuilder.create()
  .role("You are a workflow step.")
  .task("Fasse zusammen.")
  .history([{role: "user", text: "Hallo"}, {role: "model", text: "Hi"}])
  .build();

test("renders sections into system, history into messages and the task into the prompt", async () => {
  const {binding, calls} = fakeBinding({text: "Zusammenfassung"});

  const response = await createLlmGateway(new MemoryLog()).generate({binding, prompt, label: "Test", output: {kind: "text"}});

  assert.equal(response.text, "Zusammenfassung");
  assert.equal(calls[0]?.system, "<role>\nYou are a workflow step.\n</role>");
  assert.deepEqual(calls[0]?.messages, [
    {role: "user", content: [{text: "Hallo"}]}, {role: "model", content: [{text: "Hi"}]},
  ]);
  assert.equal(calls[0]?.prompt, "<task>\nFasse zusammen.\n</task>");
  assert.deepEqual(calls[0]?.config, {temperature: 0.2});
});

test("sends images as media parts after the text", async () => {
  const {binding, calls} = fakeBinding({text: "Ja"});
  const withImage = PromptBuilder.create().task("Siehst du es?").media(["data:image/png;base64,AAA"]).build();

  await createLlmGateway(new MemoryLog()).generate({binding, prompt: withImage, label: "Bild", output: {kind: "text"}});

  assert.deepEqual(calls[0]?.prompt, [{text: "<task>\nSiehst du es?\n</task>"}, {media: {url: "data:image/png;base64,AAA"}}]);
  assert.equal(calls[0]?.system, undefined, "no system part without system sections");
});

test("derives schema and result from the output kind", async () => {
  const cases: Array<[LlmOutputSpec, object, unknown]> = [
    [{kind: "choice", choices: ["ja", "nein"]}, {text: "", output: {answer: "ja"}}, "ja"],
    [{kind: "structured", fields: [{name: "summe", description: "", type: "number"}]}, {text: "", output: {summe: 3}}, {summe: 3}],
  ];
  for (const [output, result, data] of cases) {
    const {binding, calls} = fakeBinding(result);
    const response = await createLlmGateway(new MemoryLog()).generate({binding, prompt, label: "Schema", output});
    assert.ok(calls[0]?.output?.schema, `${output.kind} sends a schema`);
    assert.deepEqual(response.data, data);
  }
});

test("asks image models for the image modality and returns the data URL", async () => {
  const {binding, calls} = fakeBinding({text: "", media: {url: "data:image/png;base64,BBB"}});

  const response = await createLlmGateway(new MemoryLog()).generate({binding, prompt, label: "Bild", output: {kind: "image"}});

  assert.deepEqual(calls[0]?.config, {responseModalities: ["IMAGE"]});
  assert.equal(response.mediaUrl, "data:image/png;base64,BBB");
});

test("logs the rendered prompt and the answer around each call", async () => {
  const log = new MemoryLog();
  const {binding} = fakeBinding({text: "Fertig"});

  await createLlmGateway(log).generate({binding, prompt, label: "Prompt / Text", output: {kind: "text"}});

  assert.equal(log.starts[0]?.label, "Prompt / Text");
  assert.equal(log.starts[0]?.system, "<role>\nYou are a workflow step.\n</role>");
  assert.equal(log.starts[0]?.user, "<task>\nFasse zusammen.\n</task>");
  assert.equal(log.ends[0]?.text, "Fertig");
});

test("translates Genkit errors and logs only the start of a failed call", async () => {
  const log = new MemoryLog();
  const binding = {...fakeBinding({}).binding, ai: {generate: () => Promise.reject(new GenkitError({status: "UNAVAILABLE", message: "down"}))}} as never;

  await assert.rejects(
    createLlmGateway(log).generate({binding, prompt, label: "Fehler", output: {kind: "text"}}),
    ModelProviderUnavailableError,
  );
  assert.equal(log.starts.length, 1);
  assert.equal(log.ends.length, 0);
});

function fakeBinding(result: object): {binding: GenkitLlmBinding; calls: GenerateOptions[]} {
  const calls: GenerateOptions[] = [];
  const ai = {generate: (options: GenerateOptions) => {
    calls.push(options);
    return Promise.resolve(result);
  }};
  return {binding: {ai: ai as never, model: "model" as never, config: {temperature: 0.2}, logContext: {}}, calls};
}

class MemoryLog implements LlmCallLog {
  readonly starts: LlmCallStarted[] = [];
  readonly ends: LlmCallFinished[] = [];

  started(entry: LlmCallStarted): void {
    this.starts.push(entry);
  }

  finished(entry: LlmCallFinished): void {
    this.ends.push(entry);
  }
}
