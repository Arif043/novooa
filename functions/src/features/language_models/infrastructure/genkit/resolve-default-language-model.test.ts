import assert from "node:assert/strict";
import test from "node:test";
import {type ResolvedGenkitLanguageModel} from "./genkit-language-model-resolver.js";
import {noDefaultLanguageModelMessage, resolveDefaultLanguageModel} from "./resolve-default-language-model.js";

const resolved = {model: "m", ai: {}} as unknown as ResolvedGenkitLanguageModel;
const defaults = (blockModelId: string | null) => ({
  loadDefaults: async () => ({blockModelId}),
  saveDefaults: async () => undefined,
});

test("nutzt das gewählte Standardmodell des Nutzers", async () => {
  const asked: string[] = [];
  const resolver = {resolve: async (_team: string, id: string) => { asked.push(id); return resolved; }};

  assert.equal(await resolveDefaultLanguageModel("team", resolver, defaults("model-1")), resolved);
  assert.deepEqual(asked, ["model-1"]);
});

test("ohne Standardmodell bekommt der Nutzer einen Hinweis, kein Modell des Betreibers", async () => {
  const resolver = {resolve: async () => resolved};

  await assert.rejects(resolveDefaultLanguageModel("team", resolver, defaults(null)), new Error(noDefaultLanguageModelMessage));
});

test("ein gelöschtes Standardmodell führt zum selben Hinweis", async () => {
  const resolver = {resolve: async () => { throw new Error("nicht gefunden"); }};

  await assert.rejects(resolveDefaultLanguageModel("team", resolver, defaults("deleted")), new Error(noDefaultLanguageModelMessage));
});
