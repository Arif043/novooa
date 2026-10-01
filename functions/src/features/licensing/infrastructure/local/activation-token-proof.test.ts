import assert from "node:assert/strict";
import test from "node:test";
import {activationTokenProofFor, matchesActivationTokenProof} from "../activation-token-proof.js";

const proof = activationTokenProofFor("A3K9N7P2Q4R6T8W5");

test("accepts the redeemed token in any typed notation", () => {
  assert.equal(matchesActivationTokenProof(proof, "A3K9N7P2Q4R6T8W5"), true);
  assert.equal(matchesActivationTokenProof(proof, " a3k9-n7p2-q4r6-t8w5 "), true);
});

test("rejects other tokens, malformed input and a missing proof", () => {
  assert.equal(matchesActivationTokenProof(proof, "B3K9N7P2Q4R6T8W5"), false);
  assert.equal(matchesActivationTokenProof(proof, "kein-token"), false);
  assert.equal(matchesActivationTokenProof(proof, undefined), false);
  assert.equal(matchesActivationTokenProof(undefined, "A3K9N7P2Q4R6T8W5"), false);
});
