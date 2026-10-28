import assert from "node:assert/strict";
import test from "node:test";
import {publicUrlsIn} from "./assistant-url-context-prompt.js";

test("normalizes a naked domain for Genkit URL Context", () => {
  assert.deepEqual(publicUrlsIn("Fasse laraevent.de zusammen."), ["https://laraevent.de/"]);
});

test("does not treat an email address as a webpage", () => {
  assert.deepEqual(publicUrlsIn("Schreibe an team@novooa.de."), []);
});

test("keeps an uppercase URL scheme", () => {
  assert.deepEqual(publicUrlsIn("Prüfe HTTPS://novooa.de/preise."), ["https://novooa.de/preise"]);
});
