import assert from "node:assert/strict";
import test from "node:test";
import {CachedAssistantModelSettings} from "./cached-assistant-model-settings.js";

test("lädt einmal, hält den Wert fünf Minuten und lädt dann neu", async () => {
  let now = 0;
  let value: string | null = "gemini-2.5-flash";
  let loads = 0;
  const settings = new CachedAssistantModelSettings(async () => { loads++; return value; }, undefined, () => now);

  assert.equal(await settings.modelName(), "gemini-2.5-flash");
  value = "gemini-2.5-pro";
  now = 299_999;
  assert.equal(await settings.modelName(), "gemini-2.5-flash");
  now = 300_000;
  assert.equal(await settings.modelName(), "gemini-2.5-pro");
  assert.equal(loads, 2);
});

test("bei einem Fehler bleibt der letzte Wert, und nach 30 Sekunden wird erneut versucht", async () => {
  let now = 0;
  let fail = false;
  let loads = 0;
  const failures: unknown[] = [];
  const settings = new CachedAssistantModelSettings(
    async () => { loads++; if (fail) throw new Error("offline"); return "gemini-2.5-flash"; },
    (error) => failures.push(error), () => now,
  );

  await settings.modelName();
  fail = true;
  now = 300_000;
  assert.equal(await settings.modelName(), "gemini-2.5-flash", "letzter bekannter Wert");
  now = 329_999;
  await settings.modelName();
  assert.equal(loads, 2, "kein Neuversuch innerhalb von 30 Sekunden");
  now = 330_000;
  fail = false;
  await settings.modelName();
  assert.equal(loads, 3);
  assert.equal(failures.length, 1);
});

test("scheitert schon das erste Laden, gibt es keinen Namen", async () => {
  const settings = new CachedAssistantModelSettings(async () => { throw new Error("offline"); });

  assert.equal(await settings.modelName(), null);
});

test("gleichzeitige Anfragen teilen sich ein Laden", async () => {
  let loads = 0;
  const settings = new CachedAssistantModelSettings(async () => { loads++; return "gemini-2.5-flash"; });

  await Promise.all([settings.modelName(), settings.modelName(), settings.modelName()]);

  assert.equal(loads, 1);
});
