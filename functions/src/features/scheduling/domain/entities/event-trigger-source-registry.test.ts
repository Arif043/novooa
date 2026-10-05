import assert from "node:assert/strict";
import test from "node:test";
import {eventTriggerConfigFrom, isEventTriggerSource} from "./event-trigger-config.js";
import {createDefaultEventTriggerSourceRegistry, EventTriggerSourceRegistry} from "./event-trigger-source-registry.js";

test("die Standard-Registry kennt alle eingebauten Quellen", () => {
  const registry = createDefaultEventTriggerSourceRegistry();
  for (const id of [
    "emailReceived", "smsMessageReceived", "whatsappMessageReceived",
    "fileCreated", "fileVersionCreated", "fileDeleted", "webhookReceived",
  ]) {
    assert.equal(registry.has(id), true, id);
    assert.equal(isEventTriggerSource(id), true, id);
  }
  assert.equal(isEventTriggerSource("unbekannt"), false);
  assert.equal(isEventTriggerSource(7), false);
});

test("prepare ergänzt die Konfiguration nur für Quellen mit Hook", () => {
  const registry = new EventTriggerSourceRegistry()
    .register({id: "mit-hook", prepare: (config) => ({...config, filter: "ergänzt"})})
    .register({id: "ohne-hook"});
  assert.equal(registry.prepare(eventTriggerConfigFrom({source: "mit-hook"})).filter, "ergänzt");
  assert.equal(registry.prepare(eventTriggerConfigFrom({source: "ohne-hook"})).filter, "");
  assert.equal(registry.prepare(eventTriggerConfigFrom({source: "fremd"})).source, "fremd");
});
