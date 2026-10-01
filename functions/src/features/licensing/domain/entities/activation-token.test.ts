import assert from "node:assert/strict";
import test from "node:test";
import {runtimeActivationTokenFrom} from "./activation-token.js";

test("normalizes a sixteen-character customer token", () => {
  assert.equal(runtimeActivationTokenFrom("a3k9-n7p2-q4r6-t8w5"), "A3K9N7P2Q4R6T8W5");
});

test("rejects tokens that are not exactly sixteen supported characters", () => {
  assert.throws(() => runtimeActivationTokenFrom("A3K9N7P2Q4R6T8W"));
  assert.throws(() => runtimeActivationTokenFrom("A3K9N7P2Q4R6T8W0"));
  assert.throws(() => runtimeActivationTokenFrom("A3K9N7P2Q4R6"));
});
