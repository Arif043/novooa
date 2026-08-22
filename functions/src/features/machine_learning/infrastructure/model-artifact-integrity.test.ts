import assert from "node:assert/strict";
import {createHash} from "node:crypto";
import test from "node:test";
import {type ModelArtifactReference} from "../domain/entities/model-artifact-reference.js";
import {verifyModelArtifact} from "./model-artifact-integrity.js";

test("returns artifact bytes only after verifying size and checksum", () => {
  const content = new TextEncoder().encode("onnx-model-bytes");

  const verified = verifyModelArtifact(referenceFor(content), content);

  assert.deepEqual(verified, content);
});

test("rejects bytes with a mismatching checksum", () => {
  const content = new TextEncoder().encode("onnx-model-bytes");
  const reference = {...referenceFor(content), sha256: "0".repeat(64)};

  assert.throws(() => verifyModelArtifact(reference, content));
});

function referenceFor(content: Uint8Array): ModelArtifactReference {
  return {
    artifactId: "model-1",
    versionId: "v1",
    format: "onnx",
    contentType: "application/onnx",
    sizeBytes: content.byteLength,
    sha256: createHash("sha256").update(content).digest("hex"),
  };
}
