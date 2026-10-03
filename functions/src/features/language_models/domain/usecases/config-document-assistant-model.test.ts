import assert from "node:assert/strict";
import test from "node:test";
import {ConfigDocumentAssistantModel} from "./config-document-assistant-model.js";

const fallback = {modelName: async () => "gemini-fallback"};

test("liest den Namen aus dem Dokument", async () => {
  const model = new ConfigDocumentAssistantModel(async () => ({assistantModel: "gemini-2.5-flash"}), fallback);

  assert.equal(await model.modelName(), "gemini-2.5-flash");
});

test("ohne Dokument gilt der Rückfall", async () => {
  const model = new ConfigDocumentAssistantModel(async () => undefined, fallback);

  assert.equal(await model.modelName(), "gemini-fallback");
});

test("ein Dokument ohne Namen bedeutet: kein Modell, nicht der Rückfall", async () => {
  for (const document of [{assistantModel: null}, {assistantModel: ""}, {}, {assistantModel: 42}, {assistantModel: "kein Name!"}]) {
    const model = new ConfigDocumentAssistantModel(async () => document, fallback);
    assert.equal(await model.modelName(), null, JSON.stringify(document));
  }
});

test("jede Anfrage liest das Dokument neu, sodass Änderungen sofort wirken", async () => {
  let name = "gemini-2.5-flash";
  const model = new ConfigDocumentAssistantModel(async () => ({assistantModel: name}), fallback);

  assert.equal(await model.modelName(), "gemini-2.5-flash");
  name = "gemini-2.5-pro";
  assert.equal(await model.modelName(), "gemini-2.5-pro");
});
