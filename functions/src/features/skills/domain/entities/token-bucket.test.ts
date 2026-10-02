import assert from "node:assert/strict";
import test from "node:test";
import {defaultBucketConfig, normalizedBucketConfig, takeToken, type BucketConfig, type BucketState} from "./token-bucket.js";

const config: BucketConfig = {capacity: 20, refillPerSecond: 0.5};

test("the defaults are a burst of 20 and 30 requests per minute", () => {
  assert.deepEqual(defaultBucketConfig, {capacity: 20, refillPerSecond: 0.5});
});

test("a new bucket is full: 20 requests pass, the 21st is rejected", () => {
  let state: BucketState | undefined;
  for (let call = 0; call < 20; call++) {
    const taken = takeToken(state, config, 1_000);
    assert.equal(taken.allowed, true, `call ${call + 1}`);
    state = taken.state;
  }

  const rejected = takeToken(state, config, 1_000);
  assert.equal(rejected.allowed, false);
  assert.equal(rejected.retryAfterSeconds, 2);
});

test("the bucket refills with the elapsed time and never beyond its capacity", () => {
  const empty: BucketState = {tokens: 0, updatedAtMs: 0, expiresAtMs: 0};

  assert.equal(takeToken(empty, config, 1_999).allowed, false);
  assert.equal(takeToken(empty, config, 2_000).allowed, true);
  assert.equal(takeToken(empty, config, 10_000).state.tokens, 4, "5 refilled, 1 taken");
  assert.equal(takeToken(empty, config, 3_600_000).state.tokens, 19, "capped at 20, 1 taken");
});

test("the wait time rounds up to the next whole second and is at least one second", () => {
  const nearlyOne: BucketState = {tokens: 0.9, updatedAtMs: 0, expiresAtMs: 0};
  const half: BucketState = {tokens: 0.5, updatedAtMs: 0, expiresAtMs: 0};
  const fast: BucketConfig = {capacity: 5, refillPerSecond: 100};

  assert.equal(takeToken(nearlyOne, config, 0).retryAfterSeconds, 1);
  assert.equal(takeToken(half, config, 0).retryAfterSeconds, 1);
  assert.equal(takeToken({tokens: 0, updatedAtMs: 0, expiresAtMs: 0}, fast, 0).retryAfterSeconds, 1);
  assert.equal(takeToken({tokens: 0, updatedAtMs: 0, expiresAtMs: 0}, {capacity: 5, refillPerSecond: 0.1}, 0).retryAfterSeconds, 10);
});

test("a clock that runs backwards never adds or removes tokens", () => {
  const state: BucketState = {tokens: 3, updatedAtMs: 10_000, expiresAtMs: 0};

  assert.equal(takeToken(state, config, 5_000).state.tokens, 2);
});

test("a lowered capacity applies immediately", () => {
  const full: BucketState = {tokens: 20, updatedAtMs: 0, expiresAtMs: 0};

  assert.equal(takeToken(full, {capacity: 5, refillPerSecond: 0.5}, 0).state.tokens, 4);
});

test("the stored state expires only once the bucket would be full anyway, at least after a day", () => {
  const day = 24 * 60 * 60 * 1000;

  assert.equal(takeToken(undefined, config, 0).state.expiresAtMs, day);
  assert.equal(takeToken(undefined, {capacity: 10_000, refillPerSecond: 0.01}, 0).state.expiresAtMs, 10_000 / 0.01 * 1000);
});

test("invalid configuration values fall back to the defaults, valid ones are kept and capped", () => {
  assert.deepEqual(normalizedBucketConfig({capacity: 0, refillPerSecond: 0}), defaultBucketConfig);
  assert.deepEqual(normalizedBucketConfig({capacity: -3, refillPerSecond: -1}), defaultBucketConfig);
  assert.deepEqual(normalizedBucketConfig({capacity: Number.NaN, refillPerSecond: Number.POSITIVE_INFINITY}), defaultBucketConfig);
  assert.deepEqual(normalizedBucketConfig({}), defaultBucketConfig);
  assert.deepEqual(normalizedBucketConfig({capacity: 50.9, refillPerSecond: 2}), {capacity: 50, refillPerSecond: 2});
  assert.deepEqual(normalizedBucketConfig({capacity: 1e9, refillPerSecond: 1e9}), {capacity: 10_000, refillPerSecond: 1_000});
  assert.deepEqual(normalizedBucketConfig({capacity: 0, refillPerSecond: 3}), {capacity: 20, refillPerSecond: 3}, "each value on its own");
});
