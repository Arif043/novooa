import assert from "node:assert/strict";
import {Writable} from "node:stream";
import test from "node:test";
import {FirebaseModelArtifactPublisher} from "./firebase-model-artifact-publisher.js";

test("uploads a versioned artifact without allowing an overwrite", async () => {
  const bucket = new Bucket();
  await new FirebaseModelArtifactPublisher(bucket).publish(publication());

  assert.equal(bucket.path, "model-artifacts/model/versions/1/model.onnx");
  assert.equal(bucket.options?.preconditionOpts.ifGenerationMatch, 0);
  assert.equal(bucket.options?.metadata.contentType, "application/onnx");
  assert.deepEqual(bucket.bytes, [1, 2, 3]);
});

class Bucket {
  path: string | undefined;
  options: {preconditionOpts: {ifGenerationMatch: number}; metadata: {contentType: string}} | undefined;
  readonly bytes: number[] = [];

  file(path: string) {
    this.path = path;
    return {createWriteStream: (options: typeof this.options) => this.stream(options)};
  }

  private stream(options: typeof this.options): Writable {
    this.options = options;
    return new Writable({write: (chunk, _, done) => {
      this.bytes.push(...chunk as Buffer);
      done();
    }});
  }
}

function publication() {
  return {
    reference: {
      artifactId: "model", versionId: "1", format: "onnx" as const, contentType: "application/onnx",
      sizeBytes: 3, sha256: "0".repeat(64),
    },
    content: bytes(),
  };
}

async function* bytes(): AsyncGenerator<Uint8Array> {
  yield Uint8Array.from([1, 2, 3]);
}
