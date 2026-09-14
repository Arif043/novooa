import assert from "node:assert/strict";
import test from "node:test";
import {runtimeActivationTokenFrom} from "./activation-token.js";

test("normalizes a twelve-character customer token", () => {
  assert.equal(runtimeActivationTokenFrom("a3k9-n7p2-q4r6"), "A3K9N7P2Q4R6");
});

test("rejects tokens that are not exactly twelve supported characters", () => {
  assert.throws(() => runtimeActivationTokenFrom("A3K9N7P2Q4R"));
  assert.throws(() => runtimeActivationTokenFrom("A3K9N7P2Q4R0"));
});
