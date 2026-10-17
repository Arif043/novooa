import assert from "node:assert/strict";
import test from "node:test";
import {
  defaultGenerationOptions,
  generationOptionsFrom,
  InvalidGenerationOptionError,
  Temperature,
  TokenLimit,
} from "./generation-options.js";

test("without stored options the model decides everything", () => {
  assert.deepEqual(generationOptionsFrom(undefined), defaultGenerationOptions);
  assert.deepEqual(generationOptionsFrom({}), {
    temperature: undefined, maxOutputTokens: undefined, contextWindow: undefined, thinking: "modelDefault",
  });
});

test("builds value objects from stored numbers", () => {
  const options = generationOptionsFrom({temperature: 0.2, maxOutputTokens: 512, contextWindow: 16384, thinking: "off"});

  assert.equal(options.temperature?.value, 0.2);
  assert.equal(options.maxOutputTokens?.value, 512);
  assert.equal(options.contextWindow?.value, 16384);
  assert.equal(options.thinking, "off");
});

test("temperature stays between 0 and 2", () => {
  assert.equal(Temperature.of(0).value, 0);
  assert.equal(Temperature.of(2).value, 2);
  assert.throws(() => Temperature.of(-0.1), InvalidGenerationOptionError);
  assert.throws(() => Temperature.of(2.1), InvalidGenerationOptionError);
  assert.throws(() => Temperature.of(Number.NaN), InvalidGenerationOptionError);
});

test("token limits are positive whole numbers", () => {
  assert.equal(TokenLimit.of(1).value, 1);
  assert.throws(() => TokenLimit.of(0), InvalidGenerationOptionError);
  assert.throws(() => TokenLimit.of(1.5), InvalidGenerationOptionError);
  assert.throws(() => generationOptionsFrom({contextWindow: -4}), InvalidGenerationOptionError);
});
