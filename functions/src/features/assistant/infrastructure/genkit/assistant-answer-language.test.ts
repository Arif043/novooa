import assert from "node:assert/strict";
import test from "node:test";
import {promptWithAnswerLanguage} from "./assistant-answer-language.js";
import {assistantLocaleFrom} from "../../domain/entities/assistant-locale.js";

test("leaves the prompt unchanged for clients that send no locale", () => {
  assert.equal(promptWithAnswerLanguage("Hallo", undefined), "Hallo");
});

test("asks for the answer language of the app", () => {
  assert.match(promptWithAnswerLanguage("Hello", "en"), /Antwortsprache: English/);
  assert.match(promptWithAnswerLanguage("Hallo", "de"), /Antwortsprache: Deutsch/);
  assert.match(promptWithAnswerLanguage("Merhaba", "tr"), /Antwortsprache: Türkçe/);
});

test("ignores unsupported locales", () => {
  assert.equal(assistantLocaleFrom("fr"), undefined);
  assert.equal(assistantLocaleFrom("tr"), "tr");
  assert.equal(assistantLocaleFrom("de"), "de");
});
