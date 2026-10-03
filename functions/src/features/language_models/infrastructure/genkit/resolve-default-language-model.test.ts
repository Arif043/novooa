import assert from "node:assert/strict";
import test from "node:test";
import {type ResolvedGenkitLanguageModel} from "./genkit-language-model-resolver.js";
import {noDefaultLanguageModelMessage, resolveDefaultLanguageModel} from "./resolve-default-language-model.js";

const resolved = {model: "m", ai: {}} as unknown as ResolvedGenkitLanguageModel;
const defaults = (blockModelId: string | null, knowledgeAssistantModelId: string | null = null) => ({
  loadDefaults: async () => ({blockModelId, knowledgeAssistantModelId}),
  saveDefaults: async () => undefined,
});

function recordingResolver() {
  const asked: string[] = [];
  return {asked, resolver: {resolve: async (_team: string, id: string) => { asked.push(id); return resolved; }}};
}

test("nutzt das eigens für den Agenten gewählte Modell", async () => {
  const {asked, resolver} = recordingResolver();

  assert.equal(await resolveDefaultLanguageModel("team", resolver, defaults("standard", "agent")), resolved);
  assert.deepEqual(asked, ["agent"]);
});

test("ohne eigene Wahl gilt das Standardmodell des Nutzers", async () => {
  const {asked, resolver} = recordingResolver();

  await resolveDefaultLanguageModel("team", resolver, defaults("standard"));

  assert.deepEqual(asked, ["standard"]);
});

test("ohne jedes Modell bekommt der Nutzer einen Hinweis, kein Modell des Betreibers", async () => {
  const {resolver} = recordingResolver();

  await assert.rejects(resolveDefaultLanguageModel("team", resolver, defaults(null)), new Error(noDefaultLanguageModelMessage));
});

test("ein gelöschtes Modell führt zum selben Hinweis", async () => {
  const resolver = {resolve: async () => { throw new Error("nicht gefunden"); }};

  await assert.rejects(resolveDefaultLanguageModel("team", resolver, defaults("deleted")), new Error(noDefaultLanguageModelMessage));
});
