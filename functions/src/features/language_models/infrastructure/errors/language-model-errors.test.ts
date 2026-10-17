import assert from "node:assert/strict";
import test from "node:test";
import {GenkitError} from "genkit";
import {translateGenkitError, withTranslatedGenkitErrors} from "./genkit-error-translator.js";
import {languageModelFailureFrom} from "./language-model-failure-mapper.js";
import {
  ModelOutputSchemaError,
  ModelProviderUnavailableError,
  ModelRequestRejectedError,
  ModelResponseTruncatedError,
  ModelTimeoutError,
} from "./language-model-errors.js";

const schemaViolation = new GenkitError({
  status: "INVALID_ARGUMENT",
  message: "Schema validation failed. Parse Errors:\n\n- (root): must be object",
});

test("turns Genkit's schema validation failure into our schema error", () => {
  const translated = translateGenkitError(schemaViolation);

  assert.ok(translated instanceof ModelOutputSchemaError);
  assert.equal(translated.originalError, schemaViolation);
});

test("maps Genkit status names and provider HTTP status codes", () => {
  assert.ok(translateGenkitError(new GenkitError({status: "UNAVAILABLE", message: "down"})) instanceof ModelProviderUnavailableError);
  assert.ok(translateGenkitError(new GenkitError({status: "DEADLINE_EXCEEDED", message: "slow"})) instanceof ModelTimeoutError);
  assert.ok(translateGenkitError(Object.assign(new Error("quota"), {status: 429})) instanceof ModelRequestRejectedError);
  assert.ok(translateGenkitError(Object.assign(new Error("oops"), {status: 503})) instanceof ModelProviderUnavailableError);
  assert.ok(translateGenkitError(new TypeError("fetch failed")) instanceof ModelProviderUnavailableError);
});

test("keeps our own errors and leaves unknown errors untouched", () => {
  const ours = new ModelResponseTruncatedError("abgeschnitten");
  const unknown = new Error("etwas anderes");

  assert.equal(translateGenkitError(ours), ours);
  assert.equal(translateGenkitError(unknown), unknown);
});

test("withTranslatedGenkitErrors rethrows framework errors as ours", async () => {
  await assert.rejects(withTranslatedGenkitErrors(async () => { throw schemaViolation; }), ModelOutputSchemaError);
});

test("maps our exceptions to failure codes and everything else to unknown", () => {
  const truncated = languageModelFailureFrom(new ModelResponseTruncatedError("Kontextfenster erschöpft."));

  assert.equal(truncated.code, "responseTruncated");
  assert.equal(truncated.message, "Kontextfenster erschöpft.");
  assert.equal(languageModelFailureFrom(new ModelOutputSchemaError("x")).code, "outputSchemaViolated");
  assert.equal(languageModelFailureFrom(new Error("x")).code, "unknown");
  assert.equal(languageModelFailureFrom("text").message, "text");
});
