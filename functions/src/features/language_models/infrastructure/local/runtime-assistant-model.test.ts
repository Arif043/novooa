import assert from "node:assert/strict";
import test from "node:test";
import {RuntimeAssistantModel} from "./runtime-assistant-model.js";

test("ohne Dokument gilt kein Modell", async () => {
  assert.equal(await new RuntimeAssistantModel().modelName(), null);
});

test("übernimmt den Namen aus dem Dokument und folgt Änderungen", async () => {
  const model = new RuntimeAssistantModel();

  model.update({assistantModel: "gemini-2.5-flash"});
  assert.equal(await model.modelName(), "gemini-2.5-flash");
  model.update({assistantModel: "gemini-2.5-pro"});
  assert.equal(await model.modelName(), "gemini-2.5-pro");
});

test("ein leerer oder ungültiger Name und ein gelöschtes Dokument setzen das Modell zurück", async () => {
  const model = new RuntimeAssistantModel();
  for (const document of [{assistantModel: null}, {assistantModel: "kein Name!"}, {assistantModel: 1}, undefined]) {
    model.update({assistantModel: "gemini-2.5-flash"});
    model.update(document);
    assert.equal(await model.modelName(), null, JSON.stringify(document));
  }
});
