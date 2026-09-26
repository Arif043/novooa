import assert from "node:assert/strict";
import test from "node:test";
import {modelArtifactDistributionFromUnknown} from "./model-artifact-distribution.js";

test("decodes an immutable Hugging Face distribution", () => {
  const distribution = modelArtifactDistributionFromUnknown({
    type: "huggingFace",
    repository: "novooa/example-model",
    revision: "a".repeat(40),
    path: "model.onnx",
  });

  assert.equal(distribution.repository, "novooa/example-model");
});

test("rejects a mutable Hugging Face revision", () => {
  assert.throws(() => modelArtifactDistributionFromUnknown({
    type: "huggingFace",
    repository: "novooa/example-model",
    revision: "main",
    path: "model.onnx",
  }));
});
