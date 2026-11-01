import assert from "node:assert/strict";
import test from "node:test";
import {GenkitError} from "genkit";
import {isRetryableModelError} from "../genkit/language-model-retry.js";
import {translateGenkitError} from "./genkit-error-translator.js";
import {ModelCapabilityMissingError, ModelRequestRejectedError} from "./language-model-errors.js";
import {missingCapabilityIn} from "./missing-capability-detection.js";

test("recognises typical provider rejections of a capability", () => {
  const cases: Array<[string, string | undefined]> = [
    ["registry.ollama.ai/library/gemma:2b does not support tools", "Werkzeugaufrufe"],
    ["Function calling is not enabled for models/gemma-3", "Werkzeugaufrufe"],
    ["registry.ollama.ai/library/llama3 does not support images", "Bildeingaben"],
    ["image_url is not supported by this model", "Bildeingaben"],
    ["Response modalities IMAGE is not supported by this model.", "Bildgenerierung"],
    ["response_format json_schema is not supported", "strukturierte Ausgabe"],
    ["\"llama3\" does not support thinking", "den Denkmodus"],
    ["Invalid API key", undefined],
    ["Rate limit exceeded", undefined],
  ];
  for (const [message, capability] of cases) assert.equal(missingCapabilityIn(new Error(message)), capability, message);
});

test("finds the rejection in the cause of an already translated error", () => {
  const rejected = new ModelRequestRejectedError("Anfrage abgelehnt", new Error("model does not support tools"));

  assert.equal(missingCapabilityIn(rejected), "Werkzeugaufrufe");
});

test("translates a rejection into a readable missing capability and never retries it", () => {
  const rejection = new GenkitError({status: "INVALID_ARGUMENT", message: "Function calling is not enabled for this model"});

  const translated = translateGenkitError(rejection);

  assert.ok(translated instanceof ModelCapabilityMissingError);
  assert.equal(translated.message, "Das gewählte Sprachmodell unterstützt Werkzeugaufrufe nicht. Wähle ein anderes Modell.");
  assert.equal(isRetryableModelError(new Error("model does not support tools")), false);
});
