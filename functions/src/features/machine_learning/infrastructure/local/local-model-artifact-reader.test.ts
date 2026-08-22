import assert from "node:assert/strict";
import {createHash} from "node:crypto";
import {mkdtemp, mkdir, rm, writeFile} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {type ModelArtifactReference} from "../../domain/entities/model-artifact-reference.js";
import {modelArtifactStoragePathFor} from "../model-artifact-storage-path.js";
import {LocalModelArtifactReader} from "./local-model-artifact-reader.js";

test("reads a verified artifact from the local runtime directory", async () => {
  const rootDirectory = await mkdtemp(path.join(os.tmpdir(), "novooa-model-"));
  const content = new TextEncoder().encode("onnx-model-bytes");
  const reference = referenceFor(content);

  try {
    await writeArtifact(rootDirectory, reference, content);
    const read = await new LocalModelArtifactReader(rootDirectory).read(reference);
    assert.deepEqual([...read], [...content]);
  } finally {
    await rm(rootDirectory, {recursive: true, force: true});
  }
});

async function writeArtifact(
  rootDirectory: string,
  reference: ModelArtifactReference,
  content: Uint8Array,
): Promise<void> {
  const destination = path.join(rootDirectory, modelArtifactStoragePathFor(reference));
  await mkdir(path.dirname(destination), {recursive: true});
  await writeFile(destination, content);
}

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
