import assert from "node:assert/strict";
import test from "node:test";
import {type ServerTemplate} from "firebase-admin/remote-config";
import {assistantModelKey, RemoteConfigAssistantModel} from "./remote-config-assistant-model.js";

function templateWith(value: () => string, loads: {count: number}, failLoad = () => false): ServerTemplate {
  return {
    load: async () => { loads.count++; if (failLoad()) throw new Error("offline"); },
    evaluate: () => ({getString: (key: string) => (key === assistantModelKey ? value() : "")}),
    set: () => undefined,
    toJSON: () => ({}),
  } as unknown as ServerTemplate;
}

test("liest den Modellnamen, cached ihn fünf Minuten und lädt dann neu", async () => {
  let now = 0;
  let value = "gemini-2.5-flash";
  const loads = {count: 0};
  const remote = new RemoteConfigAssistantModel(() => templateWith(() => value, loads), () => now);

  assert.equal(await remote.modelName(), "gemini-2.5-flash");
  value = "gemini-2.5-pro";
  now = 299_999;
  assert.equal(await remote.modelName(), "gemini-2.5-flash");
  now = 300_000;
  assert.equal(await remote.modelName(), "gemini-2.5-pro");
  assert.equal(loads.count, 2);
});

test("ein leerer oder ungültiger Wert bedeutet: kein Modell festgelegt", async () => {
  for (const raw of ["", "kein gültiger Name"]) {
    const remote = new RemoteConfigAssistantModel(() => templateWith(() => raw, {count: 0}), () => 0);
    assert.equal(await remote.modelName(), null, raw);
  }
});

test("bei einem Fehler bleibt der letzte Wert, und nach 30 Sekunden wird erneut versucht", async () => {
  let now = 0;
  let fail = false;
  const loads = {count: 0};
  const remote = new RemoteConfigAssistantModel(
    () => templateWith(() => "gemini-2.5-flash", loads, () => fail), () => now,
  );

  assert.equal(await remote.modelName(), "gemini-2.5-flash");
  fail = true;
  now = 300_000;
  assert.equal(await remote.modelName(), "gemini-2.5-flash", "letzter bekannter Wert");
  now = 329_999;
  await remote.modelName();
  assert.equal(loads.count, 2, "kein Neuversuch innerhalb von 30 Sekunden");
  now = 330_000;
  fail = false;
  await remote.modelName();
  assert.equal(loads.count, 3);
});

test("scheitert schon das erste Laden, gibt es keinen Namen", async () => {
  const remote = new RemoteConfigAssistantModel(() => templateWith(() => "x", {count: 0}, () => true), () => 0);

  assert.equal(await remote.modelName(), null);
});
