import assert from "node:assert/strict";
import test from "node:test";
import {genkit, z} from "genkit";
import {PromptBuilder} from "../../../language_models/domain/prompting/prompt-builder.js";
import {AssistantActor} from "../../domain/entities/assistant-actor.js";
import {AssistantExecutionContext} from "../../domain/entities/assistant-execution-context.js";
import {AssistantRequest} from "../../domain/entities/assistant-request.js";
import {GenkitAssistantResponder} from "./genkit-assistant-responder.js";

const outputSchema = z.object({answer: z.string()});
const context = new AssistantExecutionContext(new AssistantActor("user-1"));

/** Ein Modell, das der Reihe nach die gegebenen Texte antwortet — wie ein schwaches lokales Modell. */
function responderAnswering(...texts: string[]) {
  const ai = genkit({});
  const calls: {constrained: boolean}[] = [];
  const model = ai.defineModel({name: "weak-local-model"}, async (request) => {
    calls.push({constrained: request.output?.schema !== undefined});
    return {message: {role: "model", content: [{text: texts[calls.length - 1] ?? ""}]}, finishReason: "stop"};
  });
  const responder = new GenkitAssistantResponder({
    ai, model, label: "Test-Agent", instructions: PromptBuilder.create().role("Test."), tools: [],
    modelConfig: {}, outputSchema,
    responseFromOutput: (output, text) => {
      const parsed = outputSchema.safeParse(output);
      return parsed.success ? parsed.data.answer : `Text: ${text}`;
    },
  });
  return {responder, calls};
}

test("uses the structured answer when the model keeps to the schema", async () => {
  const {responder, calls} = responderAnswering('{"answer": "Hallo"}');

  assert.equal(await responder.respond(new AssistantRequest("Hi", []), context), "Hallo");
  assert.equal(calls.length, 1);
});

test("asks again without schema and keeps the text when the model answers in prose", async () => {
  const {responder, calls} = responderAnswering("Es gibt keine Notiz dazu.", "Es gibt keine Notiz dazu.");

  assert.equal(await responder.respond(new AssistantRequest("Gibt es X?", []), context), "Text: Es gibt keine Notiz dazu.");
  assert.equal(calls.length, 2);
});

test("reads JSON from the second answer even when it is wrapped in a code fence", async () => {
  const {responder} = responderAnswering('{"falsch": 1}', 'Hier:\n```json\n{"answer": "Gefunden"}\n```');

  assert.equal(await responder.respond(new AssistantRequest("Such X", []), context), "Gefunden");
});
