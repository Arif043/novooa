import assert from "node:assert/strict";
import test from "node:test";
import {abacusAutomaticRouteModelId, discoverAbacusLanguageModels} from "./abacus-language-model-provider.js";

test("die automatische Modellwahl steht immer zuerst, auch wenn die Liste sie nicht kennt", () => {
  const models = discoverAbacusLanguageModels({data: [{id: "gpt-5"}, {id: "claude-sonnet-4"}]});

  assert.deepEqual(models.map((model) => model.modelId), [abacusAutomaticRouteModelId, "gpt-5", "claude-sonnet-4"]);
  assert.equal(models[0].name, "RouteLLM (automatische Modellwahl)");
  assert.equal(models[0].capabilities.textGeneration, true);
});

test("ein in der Liste enthaltenes route-llm wird nicht doppelt aufgeführt", () => {
  const models = discoverAbacusLanguageModels({data: [{id: "gpt-5"}, {id: "route-llm"}]});

  assert.deepEqual(models.map((model) => model.modelId), ["route-llm", "gpt-5"]);
});

test("eine leere oder ungültige Antwort liefert nur die automatische Modellwahl", () => {
  for (const value of [{data: []}, {}, null, "kaputt"]) {
    assert.deepEqual(discoverAbacusLanguageModels(value).map((model) => model.modelId), ["route-llm"]);
  }
});
