import assert from "node:assert/strict";
import test from "node:test";
import {modelBundleFor, modelBundleKey} from "./model-artifact-bundle.js";

const reference = {
  artifactId: "model", versionId: "1", format: "onnx" as const, contentType: "application/onnx",
  sizeBytes: 5, sha256: "A".repeat(64),
  externalData: [{name: "weights.bin", sizeBytes: 70, sha256: "b".repeat(64)}],
  resources: [{name: "labels.json", contentType: "application/json", sizeBytes: 3, sha256: "c".repeat(64)}],
};

test("describes all files of a model version with their paths in the model store", () => {
  const bundle = modelBundleFor(reference);

  assert.deepEqual(bundle.files.map((file) => [file.path, file.storePath]), [
    ["model.onnx", "model-artifacts/model/versions/1/model.onnx"],
    ["weights.bin", "model-artifacts/model/versions/1/weights.bin"],
    ["resources/labels.json", "model-artifacts/model/versions/1/resources/labels.json"],
  ]);
  assert.equal(bundle.files[0]?.sha256, "a".repeat(64));
});

test("derives the key like the ML service from sorted paths and checksums", () => {
  // Derselbe Wert wie novooa_bundles.bundle_file.bundle_key in Python — sonst finden sich die Bündel nicht.
  const files = [{path: "model.onnx", sha256: "a".repeat(64)}, {path: "model.onnx.data", sha256: "b".repeat(64)}];

  assert.equal(modelBundleKey(files), modelBundleKey([...files].reverse()));
  assert.equal(modelBundleKey(files), "c8e755d5630fe72fa98c65159d88d862083396d6896a80a253a87cc784bd1a52");
});
