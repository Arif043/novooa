import assert from "node:assert/strict";
import test from "node:test";
import {CachingModelArtifactReader} from "./caching-model-artifact-reader.js";
import {type ModelArtifactReader} from "../domain/repositories/model-artifact-reader.js";

test("reads a model artifact only once per immutable reference", async () => {
  const source = new RecordingArtifactReader();
  const reader = new CachingModelArtifactReader(source, 2);

  await Promise.all([reader.read(reference("one")), reader.read(reference("one"))]);

  assert.equal(source.calls, 1);
});

test("evicts the least recently used artifact", async () => {
  const source = new RecordingArtifactReader();
  const reader = new CachingModelArtifactReader(source, 1);

  await reader.read(reference("one"));
  await reader.read(reference("two"));
  await reader.read(reference("one"));

  assert.equal(source.calls, 3);
});

class RecordingArtifactReader implements ModelArtifactReader {
  calls = 0;

  async read(): Promise<Uint8Array> {
    this.calls += 1;
    return Uint8Array.from([this.calls]);
  }
}

function reference(versionId: string) {
  return {
    artifactId: "model", versionId, format: "onnx" as const,
    contentType: "application/onnx", sizeBytes: 1,
    sha256: "0000000000000000000000000000000000000000000000000000000000000000",
  };
}
