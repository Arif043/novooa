import assert from "node:assert/strict";
import test from "node:test";
import {promptWithUrlContext} from "./assistant-url-context-prompt.js";

test("normalizes a naked domain for Genkit URL Context", () => {
  const prompt = promptWithUrlContext("Fasse laraevent.de zusammen.");

  assert.match(prompt, /https:\/\/laraevent\.de\//);
  assert.match(prompt, /Nutzerfrage/);
});

test("does not treat an email address as a webpage", () => {
  const prompt = promptWithUrlContext("Schreibe an team@novooa.de.");

  assert.equal(prompt, "Schreibe an team@novooa.de.");
});

test("keeps an uppercase URL scheme", () => {
  const prompt = promptWithUrlContext("Prüfe HTTPS://novooa.de/preise.");

  assert.match(prompt, /https:\/\/novooa\.de\/preise/);
});
