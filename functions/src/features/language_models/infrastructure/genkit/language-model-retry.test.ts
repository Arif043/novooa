import assert from "node:assert/strict";
import test from "node:test";
import {GenkitError} from "genkit";
import {
  ModelProviderUnavailableError, ModelResponseTruncatedError, ModelTimeoutError,
} from "../errors/language-model-errors.js";
import {isRetryableModelError, languageModelRetry} from "./language-model-retry.js";

const noWait = {maxRetries: 3, initialDelayMs: 1, backoffFactor: 2, wait: async () => {}};
const request = {messages: []};

test("entfernte Zeitüberschreitungen werden wiederholt, lokale nicht", () => {
  assert.equal(isRetryableModelError(new ModelProviderUnavailableError("weg")), true);
  assert.equal(isRetryableModelError(new GenkitError({status: "UNAVAILABLE", message: "weg"})), true);
  assert.equal(isRetryableModelError(new ModelTimeoutError("lokales Modell langsam")), false);
  assert.equal(isRetryableModelError(new GenkitError({status: "DEADLINE_EXCEEDED", message: "Anbieter langsam"})), true);
  assert.equal(isRetryableModelError(Object.assign(new Error("SDK"), {name: "TimeoutError"})), true);
  assert.equal(isRetryableModelError(new ModelResponseTruncatedError("voll")), false);
  assert.equal(isRetryableModelError(new GenkitError({status: "INVALID_ARGUMENT", message: "nein"})), false);
});

test("eine abgeschnittene Antwort wird genau einmal versucht", async () => {
  let attempts = 0;
  const failing = async () => {
    attempts++;
    throw new ModelResponseTruncatedError("voll");
  };

  await assert.rejects(languageModelRetry(noWait)(request, failing), ModelResponseTruncatedError);
  assert.equal(attempts, 1);
});

test("ein nicht erreichbarer Anbieter wird bis zur Grenze wiederholt", async () => {
  let attempts = 0;
  const failing = async () => {
    attempts++;
    throw new ModelProviderUnavailableError("weg");
  };

  await assert.rejects(languageModelRetry(noWait)(request, failing), ModelProviderUnavailableError);
  assert.equal(attempts, 4);
});
